import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @EnvironmentObject var queue: ProcessingQueue
    @State private var isTargeted = false
    @State private var showingCompletion = false
    @State private var completionResult: ProcessingResult?

    var body: some View {
        VStack(spacing: 0) {
            OptionsBar()
                .padding()
                .background(.ultraThinMaterial)

            Divider()

            if queue.jobs.isEmpty {
                DropZoneView(isTargeted: $isTargeted)
            } else {
                VStack(spacing: 0) {
                    DropZoneView(isTargeted: $isTargeted)
                        .frame(height: 120)

                    Divider()

                    QueueListView()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .alert("Processing Complete", isPresented: $showingCompletion, presenting: completionResult) { result in
            Button("Open Folder") {
                if let url = result.outputDirectory {
                    NSWorkspace.shared.open(url)
                }
            }
            Button("Open Log") {
                LogService.shared.openLog()
            }
            Button("OK", role: .cancel) { }
        } message: { result in
            Text(result.summary)
        }
        .onReceive(queue.$processingComplete) { complete in
            if complete {
                completionResult = queue.getResult()
                showingCompletion = true
                queue.processingComplete = false
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                let supportedExtensions = ["wav", "mp3", "aiff", "aif", "flac", "m4a", "mp4", "ogg", "opus"]
                if supportedExtensions.contains(url.pathExtension.lowercased()) {
                    DispatchQueue.main.async {
                        queue.addJob(for: url)
                    }
                }
            }
        }
    }
}

struct OptionsBar: View {
    @EnvironmentObject var queue: ProcessingQueue

    var body: some View {
        HStack(spacing: 12) {
            PresetPicker()

            Divider()
                .frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Target")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Target", selection: $queue.options.targetLUFS) {
                    Text("-18 LUFS").tag(-18)
                    Text("-16 LUFS").tag(-16)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 140)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Output")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Output", selection: $queue.options.outputMode) {
                    Text("Both").tag(OutputMode.both)
                    Text("WAV").tag(OutputMode.wav)
                    Text("MP3").tag(OutputMode.mp3)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(width: 140)
            }

            if queue.options.outputMode != .wav {
                VStack(alignment: .leading, spacing: 2) {
                    Text("MP3")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Bitrate", selection: $queue.options.mp3Bitrate) {
                        Text("128k").tag(128)
                        Text("160k").tag(160)
                        Text("192k").tag(192)
                    }
                    .labelsHidden()
                    .frame(width: 75)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Sample Rate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Rate", selection: $queue.options.sampleRate) {
                    Text("44.1k").tag(44100)
                    Text("48k").tag(48000)
                }
                .labelsHidden()
                .frame(width: 80)
            }

            Spacer()

            if queue.isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else if !queue.jobs.isEmpty {
                Button("Process All") {
                    queue.startProcessing()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
    }
}

struct QueueListView: View {
    @EnvironmentObject var queue: ProcessingQueue

    var body: some View {
        List {
            ForEach(queue.jobs) { job in
                QueueItemView(job: job)
            }
            .onDelete { indexSet in
                queue.removeJobs(at: indexSet)
            }
        }
        .listStyle(.inset)
    }
}

#Preview {
    ContentView()
        .environmentObject(ProcessingQueue())
}
