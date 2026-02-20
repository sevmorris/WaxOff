import SwiftUI

struct DropZoneView: View {
    @Binding var isTargeted: Bool
    @Environment(ProcessingQueue.self) var queue

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
                )

            VStack(spacing: 12) {
                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 48))
                    .foregroundStyle(isTargeted ? Color.accentColor : .secondary)

                Text("Drop audio files here")
                    .font(.title3)
                    .foregroundStyle(.secondary)

                Text("Loudness normalization, true peak limiting, and MP3 encoding for your final mix.")
                    .font(.subheadline)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)

                Text("WAV, MP3, AIFF, FLAC, M4A, OGG")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding()
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }
}

#Preview {
    DropZoneView(isTargeted: .constant(false))
        .environment(ProcessingQueue())
        .frame(width: 400, height: 200)
}
