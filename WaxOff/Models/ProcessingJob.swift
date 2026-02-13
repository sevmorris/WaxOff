import Foundation

enum JobStatus: String {
    case pending = "Pending"
    case analyzing = "Analyzing"
    case processing = "Processing"
    case encoding = "Encoding MP3"
    case verifying = "Verifying"
    case complete = "Complete"
    case failed = "Failed"

    var isActive: Bool {
        switch self {
        case .analyzing, .processing, .encoding, .verifying:
            return true
        default:
            return false
        }
    }

    var systemImage: String {
        switch self {
        case .pending:
            return "clock"
        case .analyzing:
            return "waveform.badge.magnifyingglass"
        case .processing:
            return "waveform"
        case .encoding:
            return "music.note"
        case .verifying:
            return "checkmark.circle.badge.questionmark"
        case .complete:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        }
    }
}

struct LoudnormMeasurements {
    var inputI: Double
    var inputTP: Double
    var inputLRA: Double
    var inputThresh: Double
    var targetOffset: Double

    init?(json: [String: Any]) {
        guard let inputI = Self.parseNumber(json["input_i"]),
              let inputTP = Self.parseNumber(json["input_tp"]),
              let inputLRA = Self.parseNumber(json["input_lra"]),
              let inputThresh = Self.parseNumber(json["input_thresh"]),
              let targetOffset = Self.parseNumber(json["target_offset"]) else {
            return nil
        }

        self.inputI = inputI
        self.inputTP = inputTP
        self.inputLRA = inputLRA
        self.inputThresh = inputThresh
        self.targetOffset = targetOffset
    }

    private static func parseNumber(_ value: Any?) -> Double? {
        if let num = value as? Double {
            return num
        }
        if let str = value as? String {
            return Double(str)
        }
        return nil
    }
}

@Observable
final class ProcessingJob: Identifiable {
    let id = UUID()
    let inputURL: URL
    let addedAt: Date

    var status: JobStatus = .pending
    var progress: Double = 0
    var outputURLs: [URL] = []
    var errorMessage: String?
    var measurements: LoudnormMeasurements?
    var finalMeasurements: (i: Double, tp: Double)?

    init(inputURL: URL) {
        self.inputURL = inputURL
        self.addedAt = Date()
    }

    var filename: String {
        inputURL.lastPathComponent
    }

    var stemName: String {
        inputURL.deletingPathExtension().lastPathComponent
    }

    var outputDirectory: URL {
        inputURL.deletingLastPathComponent()
    }

    func outputFilename(for options: ProcessingOptions) -> String {
        "\(stemName)-lev-\(options.targetLUFS)LUFS"
    }
}

struct ProcessingResult {
    let successCount: Int
    let failedCount: Int
    let skippedCount: Int
    let options: ProcessingOptions
    let outputDirectory: URL?

    var summary: String {
        var lines: [String] = []

        let fileWord = successCount == 1 ? "file" : "files"
        var statusLine = "\(successCount) \(fileWord) processed successfully"
        if failedCount > 0 {
            statusLine += ", \(failedCount) failed"
        }
        lines.append(statusLine)

        if skippedCount > 0 {
            lines.append("\(skippedCount) skipped")
        }

        lines.append("")
        lines.append("Target: \(options.targetLUFS) LUFS (-1 dBTP)")
        lines.append("Sample rate: \(options.sampleRateDisplay)")
        lines.append("Output: \(options.outputMode.rawValue)")

        if options.outputMode != .wav {
            lines.append("MP3: \(options.mp3BitrateString) CBR")
        }

        lines.append("Phase rotation: \(options.phaseRotationEnabled ? "On (150 Hz)" : "Off")")

        return lines.joined(separator: "\n")
    }
}
