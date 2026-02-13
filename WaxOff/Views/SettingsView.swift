import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var queue: ProcessingQueue

    var body: some View {
        Form {
            Section("Audio Processing") {
                Picker("Target Loudness", selection: $queue.options.targetLUFS) {
                    Text("-18 LUFS (Podcast Standard)").tag(-18)
                    Text("-16 LUFS (Louder)").tag(-16)
                }

                Picker("True Peak Limit", selection: $queue.options.truePeak) {
                    Text("-1.0 dBTP").tag(-1.0)
                    Text("-1.5 dBTP").tag(-1.5)
                    Text("-2.0 dBTP").tag(-2.0)
                }

                Toggle("Phase Rotation (150 Hz allpass)", isOn: $queue.options.phaseRotationEnabled)
                    .help("All-pass filter applied before loudness normalization to improve headroom")
            }

            Section("Output") {
                Picker("Output Format", selection: $queue.options.outputMode) {
                    Text("Both WAV + MP3").tag(OutputMode.both)
                    Text("WAV Only (24-bit)").tag(OutputMode.wav)
                    Text("MP3 Only").tag(OutputMode.mp3)
                }

                if queue.options.outputMode != .wav {
                    Picker("MP3 Bitrate", selection: $queue.options.mp3Bitrate) {
                        Text("128 kbps").tag(128)
                        Text("160 kbps (Recommended)").tag(160)
                        Text("192 kbps").tag(192)
                    }
                }

                Picker("Sample Rate", selection: $queue.options.sampleRate) {
                    Text("44.1 kHz").tag(44100)
                    Text("48 kHz").tag(48000)
                }
            }

            Section("Application") {
                LabeledContent("Log File") {
                    HStack {
                        Text(LogService.shared.logPath)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Button("Open") {
                            LogService.shared.openLog()
                        }
                    }
                }

                FFmpegStatusRow()
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .navigationTitle("Settings")
    }
}

struct FFmpegStatusRow: View {
    @State private var ffmpegPath: String?
    @State private var isLoading = true

    var body: some View {
        LabeledContent("FFmpeg") {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                } else if let path = ffmpegPath {
                    Text(path)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                } else {
                    Text("Not found")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
        }
        .task {
            do {
                ffmpegPath = try await FFmpegService.shared.getFFmpegPath()
            } catch {
                ffmpegPath = nil
            }
            isLoading = false
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ProcessingQueue())
}
