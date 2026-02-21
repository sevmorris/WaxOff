import Foundation

enum FFmpegError: Error, LocalizedError {
    case notFound
    case analysisFailedNoMeasurements
    case processingFailed(String)
    case encodingFailed(String)
    case outputNotCreated

    var errorDescription: String? {
        switch self {
        case .notFound:
            return "FFmpeg not found. Please ensure FFmpeg is installed."
        case .analysisFailedNoMeasurements:
            return "Failed to analyze audio - no loudness measurements obtained."
        case .processingFailed(let msg):
            return "Processing failed: \(msg)"
        case .encodingFailed(let msg):
            return "MP3 encoding failed: \(msg)"
        case .outputNotCreated:
            return "Output file was not created."
        }
    }
}

struct FFmpegProgress {
    var phase: String
    var progress: Double
}

actor FFmpegService {
    static let shared = FFmpegService()

    private var ffmpegPath: String?

    private init() {
        ffmpegPath = Self.findFFmpegSync()
    }

    private nonisolated static func findFFmpegSync() -> String? {
        let fm = FileManager.default

        // 1. Check app bundle (bundled binary)
        if let bundledPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil),
           fm.isExecutableFile(atPath: bundledPath) {
            return bundledPath
        }

        // 2. Check bundle resources directory
        if let resourceURL = Bundle.main.resourceURL {
            let bundledURL = resourceURL.appendingPathComponent("ffmpeg")
            if fm.isExecutableFile(atPath: bundledURL.path) {
                return bundledURL.path
            }
        }

        // 3. Try copying from bundle to temp (handles sandboxing/permission issues)
        if let tempPath = try? copyBundledToTemp() {
            return tempPath
        }

        // 4. Fall back to system paths
        let searchPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        for path in searchPaths {
            if fm.isExecutableFile(atPath: path) {
                return path
            }
        }

        if let path = runWhichSync("ffmpeg") {
            return path
        }

        return nil
    }

    private nonisolated static func copyBundledToTemp() throws -> String {
        let fm = FileManager.default
        let tempBase = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent("WaxOff/bin", isDirectory: true)

        try fm.createDirectory(at: tempBase, withIntermediateDirectories: true)

        let ffmpegDst = tempBase.appendingPathComponent("ffmpeg")

        if fm.isExecutableFile(atPath: ffmpegDst.path) {
            return ffmpegDst.path
        }

        guard let sourceURL = Bundle.main.url(forResource: "ffmpeg", withExtension: nil) ??
              Bundle.main.resourceURL?.appendingPathComponent("ffmpeg"),
              fm.fileExists(atPath: sourceURL.path) else {
            throw FFmpegError.notFound
        }

        if fm.fileExists(atPath: ffmpegDst.path) {
            try? fm.removeItem(at: ffmpegDst)
        }

        try fm.copyItem(at: sourceURL, to: ffmpegDst)

        var attributes = try fm.attributesOfItem(atPath: ffmpegDst.path)
        attributes[.posixPermissions] = NSNumber(value: 0o755)
        try fm.setAttributes(attributes, ofItemAtPath: ffmpegDst.path)

        return ffmpegDst.path
    }

    private nonisolated static func runWhichSync(_ command: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()

            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            return nil
        }
        return nil
    }

    func getFFmpegPath() throws -> String {
        guard let path = ffmpegPath else {
            throw FFmpegError.notFound
        }
        return path
    }

    func process(
        job: ProcessingJob,
        options: ProcessingOptions,
        progressHandler: @escaping (FFmpegProgress) -> Void
    ) async throws -> [URL] {
        let ffmpeg = try getFFmpegPath()
        var outputURLs: [URL] = []

        LogService.shared.log("Processing: \(job.filename)")
        LogService.shared.log("Options: \(options)")

        progressHandler(FFmpegProgress(phase: "Analyzing", progress: 0))
        let measurements = try await analyzeAudio(ffmpeg: ffmpeg, input: job.inputURL, options: options)

        LogService.shared.log("Measurements: I=\(measurements.inputI), TP=\(measurements.inputTP), LRA=\(measurements.inputLRA)")

        let outputStem = job.outputFilename(for: options)
        let outputDir = job.outputDirectory

        let wavTempURL = outputDir.appendingPathComponent(".\(outputStem).part.\(UUID().uuidString.prefix(8)).wav")
        let wavFinalURL = outputDir.appendingPathComponent("\(outputStem).wav")

        progressHandler(FFmpegProgress(phase: "Processing", progress: 0.2))
        try await renderWAV(
            ffmpeg: ffmpeg,
            input: job.inputURL,
            output: wavTempURL,
            options: options,
            measurements: measurements
        ) { progress in
            progressHandler(FFmpegProgress(phase: "Processing", progress: 0.2 + progress * 0.5))
        }

        guard FileManager.default.fileExists(atPath: wavTempURL.path) else {
            throw FFmpegError.outputNotCreated
        }

        if options.outputMode == .wav || options.outputMode == .both {
            try FileManager.default.moveItem(at: wavTempURL, to: wavFinalURL)
            outputURLs.append(wavFinalURL)
            LogService.shared.log("Created WAV: \(wavFinalURL.lastPathComponent)")
        }

        if options.outputMode == .mp3 || options.outputMode == .both {
            progressHandler(FFmpegProgress(phase: "Encoding MP3", progress: 0.7))

            let sourceForMP3 = options.outputMode == .both ? wavFinalURL : wavTempURL
            let mp3TempURL = outputDir.appendingPathComponent(".\(outputStem).part.\(UUID().uuidString.prefix(8)).mp3")
            let mp3FinalURL = outputDir.appendingPathComponent("\(outputStem).mp3")

            try await encodeMP3(
                ffmpeg: ffmpeg,
                input: sourceForMP3,
                output: mp3TempURL,
                options: options
            ) { progress in
                progressHandler(FFmpegProgress(phase: "Encoding MP3", progress: 0.7 + progress * 0.25))
            }

            guard FileManager.default.fileExists(atPath: mp3TempURL.path) else {
                throw FFmpegError.encodingFailed("MP3 file was not created")
            }

            try FileManager.default.moveItem(at: mp3TempURL, to: mp3FinalURL)
            outputURLs.append(mp3FinalURL)
            LogService.shared.log("Created MP3: \(mp3FinalURL.lastPathComponent)")

            if options.outputMode == .mp3 {
                try? FileManager.default.removeItem(at: wavTempURL)
            }
        }

        progressHandler(FFmpegProgress(phase: "Verifying", progress: 0.95))

        LogService.shared.log("Processing complete for: \(job.filename)")

        return outputURLs
    }

    private func analyzeAudio(
        ffmpeg: String,
        input: URL,
        options: ProcessingOptions
    ) async throws -> LoudnormMeasurements {
        var filterChain = ""
        if options.phaseRotationEnabled {
            filterChain = "allpass=f=150,"
        }
        filterChain += "loudnorm=I=\(options.targetLUFSString):TP=\(options.truePeakString):LRA=\(options.lraString):print_format=json"

        let args = [
            "-hide_banner",
            "-nostats",
            "-y",
            "-i", input.path,
            "-af", filterChain,
            "-f", "null",
            "-"
        ]

        let (_, stderr) = try await runFFmpeg(path: ffmpeg, arguments: args)

        guard let measurements = parseLoudnormJSON(from: stderr) else {
            throw FFmpegError.analysisFailedNoMeasurements
        }

        return measurements
    }

    private func renderWAV(
        ffmpeg: String,
        input: URL,
        output: URL,
        options: ProcessingOptions,
        measurements: LoudnormMeasurements,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        var filterChain = ""
        if options.phaseRotationEnabled {
            filterChain = "allpass=f=150,"
        }
        filterChain += "loudnorm=I=\(options.targetLUFSString):TP=\(options.truePeakString):LRA=\(options.lraString)"
        filterChain += ":measured_I=\(measurements.inputI)"
        filterChain += ":measured_TP=\(measurements.inputTP)"
        filterChain += ":measured_LRA=\(measurements.inputLRA)"
        filterChain += ":measured_thresh=\(measurements.inputThresh)"
        filterChain += ":offset=\(measurements.targetOffset)"
        filterChain += ":linear=true"

        let args = [
            "-hide_banner",
            "-nostats",
            "-y",
            "-i", input.path,
            "-af", filterChain,
            "-ar", String(options.sampleRate),
            "-c:a", "pcm_s24le",
            "-f", "wav",
            output.path
        ]

        let (exitCode, stderr) = try await runFFmpeg(path: ffmpeg, arguments: args)

        if exitCode != 0 {
            throw FFmpegError.processingFailed(stderr.suffix(500).description)
        }

        progressHandler(1.0)
    }

    private func encodeMP3(
        ffmpeg: String,
        input: URL,
        output: URL,
        options: ProcessingOptions,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        let args = [
            "-hide_banner",
            "-nostats",
            "-y",
            "-i", input.path,
            "-c:a", "libmp3lame",
            "-b:a", "\(options.mp3Bitrate)k",
            "-ar", String(options.sampleRate),
            "-f", "mp3",
            output.path
        ]

        let (exitCode, stderr) = try await runFFmpeg(path: ffmpeg, arguments: args)

        if exitCode != 0 {
            throw FFmpegError.encodingFailed(stderr.suffix(500).description)
        }

        progressHandler(1.0)
    }

    private nonisolated func runFFmpeg(path: String, arguments: [String]) async throws -> (Int32, String) {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: path)
            process.arguments = arguments

            let stderrPipe = Pipe()
            process.standardOutput = FileHandle.nullDevice
            process.standardError = stderrPipe

            process.terminationHandler = { proc in
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrString = String(data: stderrData, encoding: .utf8) ?? ""
                continuation.resume(returning: (proc.terminationStatus, stderrString))
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private nonisolated func parseLoudnormJSON(from stderr: String) -> LoudnormMeasurements? {
        guard let jsonStart = stderr.range(of: "{", options: .backwards),
              let jsonEnd = stderr.range(of: "}", options: .backwards) else {
            return nil
        }

        let jsonString = String(stderr[jsonStart.lowerBound...jsonEnd.upperBound])

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        return LoudnormMeasurements(json: json)
    }
}
