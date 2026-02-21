import SwiftUI

struct HelpView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header
                section("Design Philosophy") {
                    text("""
                    WaxOff is intentionally minimal. It does one thing — finalizes your \
                    podcast mix for distribution — and exposes only the controls that \
                    matter for that job. Sensible defaults handle the rest. Drop your \
                    mix in, hit Process, and upload.
                    """)
                }
                section("Getting Started") {
                    text("""
                    WaxOff is a finalizer for podcast mixes. It applies EBU R128 loudness \
                    normalization, optional phase rotation, and encodes to 24-bit WAV and/or \
                    MP3 — ready for distribution.
                    """)
                    steps([
                        "Choose a preset or configure your target loudness, output format, and sample rate.",
                        "Drag and drop your final mix files onto the window.",
                        "Click Process All.",
                        "Output files are saved alongside the originals."
                    ])
                }
                section("Output Naming") {
                    code("{original-name}-lev-{target}LUFS.wav")
                    code("{original-name}-lev-{target}LUFS.mp3")
                    text("Example: episode-01-lev--18LUFS.wav")
                }
                section("Processing Pipeline") {
                    text("WaxOff uses FFmpeg with a multi-pass pipeline:")
                    numberedList([
                        "Analysis — measures integrated loudness, true peak, loudness range, and threshold using EBU R128 (with phase rotation if enabled).",
                        "Normalization — applies a linear gain to match the target loudness, preserving dynamics. Output as 24-bit WAV.",
                        "MP3 encoding (if selected) — encodes the normalized WAV using LAME at the chosen bitrate."
                    ])
                }
                section("Main Settings") {
                    definition("Target Loudness", "Integrated loudness target, adjustable from -24 to -14 LUFS. Common targets: -18 LUFS (podcast standard), -16 LUFS (louder), -14 LUFS (Spotify/YouTube). Normalization uses linear gain — no dynamic compression.")
                    definition("True Peak Limit", "Maximum true peak level, adjustable from -3.0 to -0.1 dBTP. Prevents inter-sample clipping on playback. -1.0 dBTP is recommended for most podcasts.")
                    definition("Output Format", "WAV only (24-bit), MP3 only, or both. MP3 is CBR at the selected bitrate and preserves the source channel count (mono or stereo).")
                    definition("MP3 Bitrate", "128, 160 (recommended), or 192 kbps constant bitrate.")
                    definition("Sample Rate", "Output sample rate — 44.1 kHz or 48 kHz.")
                }
                section("Advanced Settings (Settings Window)") {
                    definition("Phase Rotation", "150 Hz allpass filter applied before normalization. Reduces crest factor of speech, giving the normalizer more headroom.")
                    definition("Loudness Range (LRA)", "Target loudness range, fixed at 11 LU. Controls how much dynamic variation is permitted.")
                }
                section("File Management") {
                    text("""
                    Click files in the queue to select them. Use Shift-click or Command-click \
                    to select multiple files. Selected files can be removed with the Remove \
                    Selected button. You can also swipe left on individual files to delete them. \
                    Files that are actively processing cannot be removed.
                    """)
                }
                section("Presets") {
                    text("WaxOff includes built-in presets for common podcast workflows:")
                    definition("Podcast Standard", "-18 LUFS, both WAV + MP3, 160 kbps, 44.1 kHz, phase rotation on.")
                    definition("Podcast Loud", "-16 LUFS, both WAV + MP3, 160 kbps, 44.1 kHz, phase rotation on.")
                    definition("WAV Only (Mastering)", "-18 LUFS, WAV only, 48 kHz, phase rotation on.")
                    text("You can also save your own presets from the preset menu in the toolbar.")
                }
                section("Log File") {
                    text("""
                    WaxOff logs all processing details to ~/Library/Logs/WaxOff.log. \
                    Open it from the app menu (⇧⌘L) or from Settings. The log includes \
                    loudness measurements, processing options, and any errors.
                    """)
                }
                Spacer()
            }
            .padding(30)
        }
        .frame(width: 540, height: 640)
    }

    // MARK: - Components

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("WaxOff Help")
                .font(.largeTitle.bold())
            Text("Podcast Finalizer for macOS")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2.bold())
            content()
        }
    }

    private func text(_ string: String) -> some View {
        Text(string)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func code(_ string: String) -> some View {
        Text(string)
            .font(.system(.body, design: .monospaced))
            .padding(8)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func steps(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1).")
                        .font(.body.bold())
                        .frame(width: 20, alignment: .trailing)
                    Text(item)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func numberedList(_ items: [String]) -> some View {
        steps(items)
    }

    private func definition(_ term: String, _ detail: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(term)
                .font(.body.bold())
            Text(detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.bottom, 4)
    }
}

#Preview {
    HelpView()
}
