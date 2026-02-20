import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(ProcessingQueue.self) var queue
    @State private var isTargeted = false
    @State private var showingCompletion = false
    @State private var completionResult: ProcessingResult?

    var body: some View {
        @Bindable var queue = queue

        VStack(spacing: 0) {
            OptionsBar()
                .padding()
                .background(.ultraThinMaterial)

            Divider()

            if queue.jobs.isEmpty {
                DropZoneView(isTargeted: $isTargeted)
            } else {
                VStack(spacing: 0) {
                    QueueListView()

                    Divider()

                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle")
                            .foregroundStyle(.tertiary)
                        Text("Drop more files here")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
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
        .onChange(of: queue.processingComplete) { _, newValue in
            if newValue {
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
    @Environment(ProcessingQueue.self) var queue

    var body: some View {
        @Bindable var queue = queue

        HStack(spacing: 12) {
            PresetPicker()

            Divider()
                .frame(height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text("Target: \(Int(queue.options.targetLUFS)) LUFS")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $queue.options.targetLUFS, in: -24...(-14), step: 1)
                    .frame(width: 140)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("True Peak: \(queue.options.truePeakString) dBTP")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Slider(value: $queue.options.truePeak, in: -3.0...(-0.1), step: 0.1)
                    .frame(width: 120)
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
                .disabled(queue.options.outputMode == .wav)
                .opacity(queue.options.outputMode == .wav ? 0.4 : 1)
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

            Group {
                if queue.isProcessing {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Process All") {
                        queue.startProcessing()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(queue.jobs.isEmpty)
                    .opacity(queue.jobs.isEmpty ? 0.4 : 1)
                }
            }
            .frame(width: 120)
        }
    }
}

struct QueueListView: View {
    @Environment(ProcessingQueue.self) var queue
    @State private var selectedJobIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $selectedJobIDs) {
                ForEach(queue.jobs) { job in
                    QueueItemView(job: job)
                        .tag(job.id)
                }
                .onDelete { indexSet in
                    queue.removeJobs(at: indexSet)
                }
            }
            .listStyle(.inset)

            if !selectedJobIDs.isEmpty {
                Divider()
                HStack {
                    Text("\(selectedJobIDs.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Remove Selected") {
                        queue.removeJobs(withIDs: selectedJobIDs)
                        selectedJobIDs.removeAll()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                    .disabled(queue.isProcessing)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(ProcessingQueue())
}
