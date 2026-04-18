import SwiftUI

@main
struct AITerminalApp: App {
    @State private var appState = AppState()

    init() {
        // Show app icon in Dock (SPM executables default to accessory/agent mode)
        NSApplication.shared.setActivationPolicy(.regular)
        // Bring app to front on launch
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .frame(minWidth: 900, minHeight: 600)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 1280, height: 820)
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Session") {
                    appState.createSession()
                }
                .keyboardShortcut("t", modifiers: .command)

                Button("Close Session") {
                    if let id = appState.activeSessionID {
                        appState.closeSession(id)
                    }
                }
                .keyboardShortcut("w", modifiers: .command)
            }
            CommandGroup(replacing: .help) {
                Button("AI Terminal Help") {}
            }
        }

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
