import Foundation

// MARK: - AI Context

struct AIContext {
    let command: String
    let output: String
    let isError: Bool
    let currentDirectory: String
    let projectInfo: String
    let recentHistory: [String]
}

// MARK: - AI Client Protocol

protocol AIClient {
    var providerType: AIProviderType { get }
    func checkAvailability() async -> Bool
    func complete(prompt: String, systemPrompt: String) async throws -> String
    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error>
}

// MARK: - AI Error

enum AIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiKeyMissing
    case providerUnavailable
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:           return "Invalid API URL"
        case .invalidResponse:      return "Invalid response from AI provider"
        case .apiKeyMissing:        return "API key is required for this provider"
        case .providerUnavailable:  return "AI provider is not available"
        case .networkError(let m):  return "Network error: \(m)"
        }
    }
}

// MARK: - Prompt Helpers

enum AIPromptBuilder {
    static func systemPrompt(context: AIContext) -> String {
        """
        You are an expert terminal assistant running on macOS. \
        You help developers understand errors, fix commands, and automate workflows.

        Current directory: \(context.currentDirectory)
        \(context.projectInfo.isEmpty ? "" : "Project: \(context.projectInfo)")

        Rules:
        - Be concise and direct
        - Provide executable commands wrapped in ```bash code blocks
        - Explain WHY errors occur, not just how to fix them
        - Warn about dangerous commands (rm -rf, sudo, etc.)
        - Use markdown formatting for clarity
        - Number multi-step solutions
        """
    }

    static func errorPrompt(context: AIContext) -> String {
        """
        I ran this command:
        ```
        \(context.command)
        ```

        And got this output:
        ```
        \(String(context.output.prefix(3000)))
        ```

        What went wrong and how do I fix it? Provide the exact commands to run.
        """
    }

    static func explainPrompt(command: String) -> String {
        """
        Explain this command in detail. Break down each part. Mention any risks or side effects.
        ```
        \(command)
        ```
        """
    }
}
