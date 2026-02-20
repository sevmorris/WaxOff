import Foundation

enum OutputMode: String, Codable, CaseIterable {
    case wav = "WAV"
    case mp3 = "MP3"
    case both = "Both"
}

struct ProcessingOptions: Codable, Equatable {
    var targetLUFS: Double = -18
    var truePeak: Double = -1.0
    var lra: Double = 11.0
    var outputMode: OutputMode = .both
    var mp3Bitrate: Int = 160
    var sampleRate: Int = 44100
    var phaseRotationEnabled: Bool = true

    static let `default` = ProcessingOptions()

    var targetLUFSString: String {
        targetLUFS == targetLUFS.rounded() ? "\(Int(targetLUFS))" : String(format: "%.1f", targetLUFS)
    }

    var truePeakString: String {
        String(format: "%.1f", truePeak)
    }

    var lraString: String {
        String(format: "%.0f", lra)
    }

    var mp3BitrateString: String {
        "\(mp3Bitrate)k"
    }

    var sampleRateDisplay: String {
        sampleRate == 44100 ? "44.1 kHz" : "48 kHz"
    }
}
