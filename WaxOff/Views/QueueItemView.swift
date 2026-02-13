import SwiftUI

struct QueueItemView: View {
    @Bindable var job: ProcessingJob

    var body: some View {
        HStack(spacing: 12) {
            statusIcon

            VStack(alignment: .leading, spacing: 4) {
                Text(job.filename)
                    .font(.body)
                    .lineLimit(1)

                if job.status.isActive {
                    ProgressView(value: job.progress)
                        .progressViewStyle(.linear)

                    Text(job.status.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if job.status == .complete {
                    Text(outputSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if job.status == .failed {
                    Text(job.errorMessage ?? "Unknown error")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            if job.status == .complete {
                Button {
                    openOutputFolder()
                } label: {
                    Image(systemName: "folder")
                }
                .buttonStyle(.borderless)
                .help("Open output folder")
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        Group {
            switch job.status {
            case .pending:
                Image(systemName: job.status.systemImage)
                    .foregroundStyle(.secondary)
            case .analyzing, .processing, .encoding, .verifying:
                ProgressView()
                    .scaleEffect(0.7)
            case .complete:
                Image(systemName: job.status.systemImage)
                    .foregroundStyle(.green)
            case .failed:
                Image(systemName: job.status.systemImage)
                    .foregroundStyle(.red)
            }
        }
        .frame(width: 24)
    }

    private var outputSummary: String {
        let names = job.outputURLs.map { $0.lastPathComponent }
        return names.joined(separator: ", ")
    }

    private func openOutputFolder() {
        guard let firstOutput = job.outputURLs.first else { return }
        NSWorkspace.shared.activateFileViewerSelecting([firstOutput])
    }
}

#Preview {
    VStack {
        QueueItemView(job: {
            let job = ProcessingJob(inputURL: URL(fileURLWithPath: "/test/podcast-episode.wav"))
            return job
        }())

        QueueItemView(job: {
            let job = ProcessingJob(inputURL: URL(fileURLWithPath: "/test/interview.mp3"))
            job.status = .processing
            job.progress = 0.45
            return job
        }())

        QueueItemView(job: {
            let job = ProcessingJob(inputURL: URL(fileURLWithPath: "/test/final-mix.wav"))
            job.status = .complete
            job.outputURLs = [
                URL(fileURLWithPath: "/test/final-mix-lev-18LUFS.wav"),
                URL(fileURLWithPath: "/test/final-mix-lev-18LUFS.mp3")
            ]
            return job
        }())

        QueueItemView(job: {
            let job = ProcessingJob(inputURL: URL(fileURLWithPath: "/test/corrupted.wav"))
            job.status = .failed
            job.errorMessage = "Invalid audio stream"
            return job
        }())
    }
    .padding()
    .frame(width: 400)
}
