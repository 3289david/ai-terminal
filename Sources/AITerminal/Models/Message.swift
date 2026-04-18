import Foundation

// MARK: - Message Role

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
    case error
}

// MARK: - AI Message

struct AIMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let timestamp: Date
    let provider: AIProviderType?

    init(role: MessageRole, content: String, provider: AIProviderType? = nil) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.timestamp = Date()
        self.provider = provider
    }
}

// MARK: - Risk Level

enum RiskLevel: String, Codable {
    case safe
    case caution
    case dangerous
}

// MARK: - Command Suggestion

struct CommandSuggestion: Identifiable {
    let id = UUID()
    let command: String
    let explanation: String
    let risk: RiskLevel

    var riskIcon: String {
        switch risk {
        case .safe:      return Icons.checkmark
        case .caution:   return Icons.warning
        case .dangerous: return Icons.error
        }
    }
}

// MARK: - Terminal Line

struct TerminalLine: Identifiable {
    let id = UUID()
    let text: String
    let isError: Bool
    let isCommand: Bool
    let timestamp: Date

    init(text: String, isError: Bool = false, isCommand: Bool = false) {
        self.text = text
        self.isError = isError
        self.isCommand = isCommand
        self.timestamp = Date()
    }
}

// MARK: - Terminal Session

struct TerminalSession: Identifiable {
    let id: UUID
    var name: String
    var currentDirectory: String
    var isActive: Bool
    let createdAt: Date

    init(name: String = "Session", directory: String = "~") {
        self.id = UUID()
        self.name = name
        self.currentDirectory = directory
        self.isActive = true
        self.createdAt = Date()
    }
}
