import SwiftUI

@main
struct WaxOffApp: App {
    @StateObject private var processingQueue = ProcessingQueue()
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(processingQueue)
                .frame(minWidth: 600, minHeight: 450)
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 700, height: 500)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Open Log...") {
                    LogService.shared.openLog()
                }
                .keyboardShortcut("L", modifiers: [.command, .shift])
            }
            CommandGroup(replacing: .help) {
                Button("WaxOff Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }

        Window("WaxOff Help", id: "help") {
            HelpView()
        }
        .windowResizability(.contentSize)

        Settings {
            SettingsView()
                .environmentObject(processingQueue)
        }
    }
}
