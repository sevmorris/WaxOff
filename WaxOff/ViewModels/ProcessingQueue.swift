import Foundation
import SwiftUI

@MainActor
final class ProcessingQueue: ObservableObject {
    @Published var jobs: [ProcessingJob] = []
    @Published var options = ProcessingOptions.default
    @Published var isProcessing = false
    @Published var processingComplete = false

    @Published var presetStore = PresetStore()

    private var processingTask: Task<Void, Never>?

    var pendingJobs: [ProcessingJob] {
        jobs.filter { $0.status == .pending }
    }

    var completedJobs: [ProcessingJob] {
        jobs.filter { $0.status == .complete }
    }

    var failedJobs: [ProcessingJob] {
        jobs.filter { $0.status == .failed }
    }

    func addJob(for url: URL) {
        guard !jobs.contains(where: { $0.inputURL == url }) else { return }

        let job = ProcessingJob(inputURL: url)
        jobs.append(job)
        LogService.shared.log("Added to queue: \(url.lastPathComponent)")
    }

    func removeJobs(at offsets: IndexSet) {
        let jobsToRemove = offsets.map { jobs[$0] }
        for job in jobsToRemove {
            if !job.status.isActive {
                LogService.shared.log("Removed from queue: \(job.filename)")
            }
        }
        let filteredOffsets = IndexSet(offsets.filter { !jobs[$0].status.isActive })
        jobs.remove(atOffsets: filteredOffsets)
    }

    func clearCompleted() {
        jobs.removeAll { $0.status == .complete }
    }

    func clearAll() {
        guard !isProcessing else { return }
        jobs.removeAll()
    }

    func startProcessing() {
        guard !isProcessing else { return }
        guard !pendingJobs.isEmpty else { return }

        isProcessing = true
        processingComplete = false

        LogService.shared.logRunStart()
        LogService.shared.log("Starting batch processing with \(pendingJobs.count) files")
        LogService.shared.log("Options: Target=\(options.targetLUFS) LUFS, Output=\(options.outputMode.rawValue), MP3=\(options.mp3BitrateString), SR=\(options.sampleRate)")

        processingTask = Task {
            await processAllJobs()
        }
    }

    func stopProcessing() {
        processingTask?.cancel()
        processingTask = nil
        isProcessing = false
    }

    private func processAllJobs() async {
        for job in jobs where job.status == .pending {
            if Task.isCancelled { break }

            await processJob(job)
        }

        isProcessing = false
        processingComplete = true

        let result = getResult()
        LogService.shared.log("Batch complete: \(result.successCount) success, \(result.failedCount) failed")
        LogService.shared.logRunEnd()
    }

    private func processJob(_ job: ProcessingJob) async {
        job.status = .analyzing
        job.progress = 0

        do {
            let outputURLs = try await FFmpegService.shared.process(
                job: job,
                options: options
            ) { [weak self] progress in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.updateJobProgress(job, phase: progress.phase, progress: progress.progress)
                }
            }

            job.outputURLs = outputURLs
            job.status = .complete
            job.progress = 1.0

        } catch {
            job.status = .failed
            job.errorMessage = error.localizedDescription
            LogService.shared.log("Failed: \(job.filename) - \(error.localizedDescription)")
        }
    }

    private func updateJobProgress(_ job: ProcessingJob, phase: String, progress: Double) {
        switch phase {
        case "Analyzing":
            job.status = .analyzing
        case "Processing":
            job.status = .processing
        case "Encoding MP3":
            job.status = .encoding
        case "Verifying":
            job.status = .verifying
        default:
            break
        }
        job.progress = progress
    }

    func getResult() -> ProcessingResult {
        ProcessingResult(
            successCount: completedJobs.count,
            failedCount: failedJobs.count,
            skippedCount: 0,
            options: options,
            outputDirectory: completedJobs.first?.outputDirectory
        )
    }

    func applyPreset(_ preset: Preset) {
        options = preset.options
        presetStore.selectedPresetID = preset.id
    }

    func saveCurrentAsPreset(name: String) {
        presetStore.savePreset(name: name, options: options)
    }
}
