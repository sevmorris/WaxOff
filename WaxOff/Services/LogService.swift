import Foundation
import AppKit

final class LogService {
    static let shared = LogService()

    private let logURL: URL
    private let dateFormatter: DateFormatter
    private let queue = DispatchQueue(label: "com.waxoff.logging", qos: .utility)
    private var fileHandle: FileHandle?

    private init() {
        let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
            .appendingPathComponent("Logs")

        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        logURL = logsDir.appendingPathComponent("WaxOff.log")

        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }

        fileHandle = try? FileHandle(forWritingTo: logURL)
        fileHandle?.seekToEndOfFile()
    }

    func log(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let timestamp = dateFormatter.string(from: Date())
        let filename = URL(fileURLWithPath: file).lastPathComponent
        let logEntry = "[\(timestamp)] [\(filename):\(line)] \(message)\n"

        queue.async { [weak self] in
            guard let self, let data = logEntry.data(using: .utf8) else { return }
            self.fileHandle?.write(data)
        }

        #if DEBUG
        print(logEntry, terminator: "")
        #endif
    }

    func logSection(_ title: String) {
        let separator = String(repeating: "=", count: 60)
        log("\n\(separator)")
        log(title)
        log(separator)
    }

    func logRunStart() {
        logSection("Run Start - PID \(ProcessInfo.processInfo.processIdentifier)")
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
        log("WaxOff Version: \(version)")
        log("macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)")
    }

    func logRunEnd() {
        logSection("Run End - PID \(ProcessInfo.processInfo.processIdentifier)")
    }

    func openLog() {
        NSWorkspace.shared.open(logURL)
    }

    var logPath: String {
        logURL.path
    }
}
