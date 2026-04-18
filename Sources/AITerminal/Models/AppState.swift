import SwiftUI

@Observable
final class AppState {
    // Provider
    var selectedProvider: AIProviderType = .auto
    var providerConfig: ProviderConfig = ProviderConfig()
    var executionMode: ExecutionMode = .assisted

    // Sessions
    var sessions: [TerminalSession] = []
    var activeSessionID: UUID?

    // UI State
    var showSidebar: Bool = true
    var showAIPanel: Bool = true
    var showSettings: Bool = false

    var activeSession: TerminalSession? {
        get { sessions.first { $0.id == activeSessionID } }
        set {
            if let newValue, let idx = sessions.firstIndex(where: { $0.id == newValue.id }) {
                sessions[idx] = newValue
            }
        }
    }

    // MARK: - Lifecycle

    init() {
        loadSettings()
        if sessions.isEmpty { createSession() }
    }

    func createSession() {
        let session = TerminalSession(
            name: "Session \(sessions.count + 1)",
            directory: FileManager.default.homeDirectoryForCurrentUser.path
        )
        sessions.append(session)
        activeSessionID = session.id
    }

    func closeSession(_ id: UUID) {
        sessions.removeAll { $0.id == id }
        if activeSessionID == id {
            activeSessionID = sessions.last?.id
        }
        if sessions.isEmpty { createSession() }
    }

    // MARK: - Persistence

    func saveSettings() {
        if let data = try? JSONEncoder().encode(providerConfig) {
            UserDefaults.standard.set(data, forKey: "providerConfig")
        }
        UserDefaults.standard.set(selectedProvider.rawValue, forKey: "selectedProvider")
        UserDefaults.standard.set(executionMode.rawValue, forKey: "executionMode")
    }

    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: "providerConfig"),
           let config = try? JSONDecoder().decode(ProviderConfig.self, from: data) {
            providerConfig = config
        }
        if let raw = UserDefaults.standard.string(forKey: "selectedProvider"),
           let type = AIProviderType(rawValue: raw) {
            selectedProvider = type
        }
        if let raw = UserDefaults.standard.string(forKey: "executionMode"),
           let mode = ExecutionMode(rawValue: raw) {
            executionMode = mode
        }
    }
}
