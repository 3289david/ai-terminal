import SwiftUI

@main
struct AITerminalApp: App {
    @State private var appState = AppState()

    init() {
        // Show app icon in Dock (SPM executables default to accessory/agent mode)
        NSApplication.shared.setActivationPolicy(.regular)
        // Bring app to front on launch
        NSApplication.shared.activate(ignoringOtherApps: true)
        // Auto-install the CLI binary on first launch
        Self.installCLI()
    }

    /// Copies the bundled `ait` CLI binary to /usr/local/bin on first launch
    /// or when the bundled version is newer than the installed one.
    private static func installCLI() {
        DispatchQueue.global(qos: .utility).async {
            let fm = FileManager.default
            // Find the bundled ait binary next to the main executable
            guard let execURL = Bundle.main.executableURL else { return }
            let bundledAit = execURL.deletingLastPathComponent().appendingPathComponent("ait")
            guard fm.fileExists(atPath: bundledAit.path) else { return }

            let installDir = "/usr/local/bin"
            let installPath = "\(installDir)/ait"

            // Create /usr/local/bin if it doesn't exist
            if !fm.fileExists(atPath: installDir) {
                try? fm.createDirectory(atPath: installDir, withIntermediateDirectories: true)
            }

            // Skip if already installed and same size (same build)
            if fm.fileExists(atPath: installPath),
               let bundledAttrs = try? fm.attributesOfItem(atPath: bundledAit.path),
               let installedAttrs = try? fm.attributesOfItem(atPath: installPath),
               let bundledSize = bundledAttrs[.size] as? Int,
               let installedSize = installedAttrs[.size] as? Int,
               bundledSize == installedSize {
                return // Already up to date
            }

            // Copy the binary
            do {
                if fm.fileExists(atPath: installPath) {
                    try fm.removeItem(atPath: installPath)
                }
                try fm.copyItem(at: bundledAit, to: URL(fileURLWithPath: installPath))
                // Make executable
                try fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: installPath)
                print("✓ ait CLI installed to \(installPath)")
            } catch {
                // Silently fail — user might not have write access to /usr/local/bin
                print("⚠ Could not install ait CLI: \(error.localizedDescription)")
            }
        }
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
