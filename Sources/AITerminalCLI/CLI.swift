import Foundation
#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// ╔══════════════════════════════════════════════════════════════════╗
// ║  AI Terminal CLI v2.0                                           ║
// ║  Full-featured AI terminal assistant for macOS / Linux          ║
// ║  23 providers · safety layer · memory · context · streaming     ║
// ║  Deploy: brew install ai-terminal-cli / choco install ait      ║
// ╚══════════════════════════════════════════════════════════════════╝

let VERSION = "3.1.0"

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - ANSI Terminal Colors
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum C {
    static let reset     = "\u{1B}[0m"
    static let bold      = "\u{1B}[1m"
    static let dim       = "\u{1B}[2m"
    static let italic    = "\u{1B}[3m"
    static let underline = "\u{1B}[4m"
    static let red       = "\u{1B}[31m"
    static let green     = "\u{1B}[32m"
    static let yellow    = "\u{1B}[33m"
    static let blue      = "\u{1B}[34m"
    static let purple    = "\u{1B}[35m"
    static let cyan      = "\u{1B}[36m"
    static let white     = "\u{1B}[37m"
    static let gray      = "\u{1B}[90m"
    static let bgRed     = "\u{1B}[41m"
    static let bgGreen   = "\u{1B}[42m"
    static let bgYellow  = "\u{1B}[43m"
    static let bgBlue    = "\u{1B}[44m"
}

func stderr(_ msg: String) {
    FileHandle.standardError.write(Data("\(msg)\n".utf8))
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Provider Types (23 providers + auto)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum Provider: String, CaseIterable {
    case auto, ollama, lmstudio, pollinations
    case openai, anthropic, google, mistral, cohere, xai, deepseek, ai21
    case groq, cerebras, sambanova, fireworks, together, lepton
    case openrouter, deepinfra, perplexity, huggingface, replicate

    var displayName: String {
        switch self {
        case .auto: return "Auto"
        case .ollama: return "Ollama"
        case .lmstudio: return "LM Studio"
        case .pollinations: return "Pollinations"
        case .openai: return "OpenAI"
        case .anthropic: return "Anthropic"
        case .google: return "Google Gemini"
        case .mistral: return "Mistral"
        case .cohere: return "Cohere"
        case .xai: return "xAI"
        case .deepseek: return "DeepSeek"
        case .ai21: return "AI21"
        case .groq: return "Groq"
        case .cerebras: return "Cerebras"
        case .sambanova: return "SambaNova"
        case .fireworks: return "Fireworks"
        case .together: return "Together"
        case .lepton: return "Lepton"
        case .openrouter: return "OpenRouter"
        case .deepinfra: return "DeepInfra"
        case .perplexity: return "Perplexity"
        case .huggingface: return "HuggingFace"
        case .replicate: return "Replicate"
        }
    }

    var category: String {
        switch self {
        case .auto: return ""
        case .ollama, .lmstudio: return "Local"
        case .pollinations: return "Free"
        case .openai, .anthropic, .google, .mistral, .cohere, .xai, .deepseek, .ai21: return "Cloud"
        case .groq, .cerebras, .sambanova, .fireworks, .together, .lepton: return "Fast Inference"
        case .openrouter, .deepinfra, .perplexity, .huggingface, .replicate: return "Aggregator"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .auto:         return ""
        case .ollama:       return "http://localhost:11434"
        case .lmstudio:     return "http://localhost:1234/v1"
        case .pollinations: return "https://text.pollinations.ai"
        case .openai:       return "https://api.openai.com/v1"
        case .anthropic:    return "https://api.anthropic.com"
        case .google:       return "https://generativelanguage.googleapis.com/v1beta"
        case .mistral:      return "https://api.mistral.ai/v1"
        case .cohere:       return "https://api.cohere.com/compatibility/v1"
        case .xai:          return "https://api.x.ai/v1"
        case .deepseek:     return "https://api.deepseek.com"
        case .ai21:         return "https://api.ai21.com/studio/v1"
        case .groq:         return "https://api.groq.com/openai/v1"
        case .cerebras:     return "https://api.cerebras.ai/v1"
        case .sambanova:    return "https://api.sambanova.ai/v1"
        case .fireworks:    return "https://api.fireworks.ai/inference/v1"
        case .together:     return "https://api.together.xyz/v1"
        case .lepton:       return "https://llama3-1-405b.lepton.run/api/v1"
        case .openrouter:   return "https://openrouter.ai/api/v1"
        case .deepinfra:    return "https://api.deepinfra.com/v1/openai"
        case .perplexity:   return "https://api.perplexity.ai"
        case .huggingface:  return "https://api-inference.huggingface.co/v1"
        case .replicate:    return "https://api.replicate.com/v1"
        }
    }

    var defaultModel: String {
        switch self {
        case .auto:         return ""
        case .ollama:       return "llama3"
        case .lmstudio:     return "local-model"
        case .pollinations: return "openai"
        case .openai:       return "gpt-4o"
        case .anthropic:    return "claude-sonnet-4-20250514"
        case .google:       return "gemini-2.0-flash"
        case .mistral:      return "mistral-large-latest"
        case .cohere:       return "command-r-plus"
        case .xai:          return "grok-2"
        case .deepseek:     return "deepseek-chat"
        case .ai21:         return "jamba-1.5-large"
        case .groq:         return "llama-3.3-70b-versatile"
        case .cerebras:     return "llama-3.3-70b"
        case .sambanova:    return "Meta-Llama-3.3-70B-Instruct"
        case .fireworks:    return "accounts/fireworks/models/llama-v3p3-70b-instruct"
        case .together:     return "meta-llama/Llama-3.3-70B-Instruct-Turbo"
        case .lepton:       return "llama3-1-405b"
        case .openrouter:   return "anthropic/claude-sonnet-4"
        case .deepinfra:    return "meta-llama/Llama-3.3-70B-Instruct"
        case .perplexity:   return "sonar-pro"
        case .huggingface:  return "meta-llama/Llama-3.3-70B-Instruct"
        case .replicate:    return "meta/llama-3.3-70b-instruct"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .auto, .ollama, .lmstudio, .pollinations: return false
        default: return true
        }
    }

    var isLocal: Bool { self == .ollama || self == .lmstudio }

    /// Environment variable name to check for API key fallback
    var envKeyName: String? {
        switch self {
        case .openai:       return "OPENAI_API_KEY"
        case .anthropic:    return "ANTHROPIC_API_KEY"
        case .google:       return "GOOGLE_API_KEY"
        case .mistral:      return "MISTRAL_API_KEY"
        case .cohere:       return "COHERE_API_KEY"
        case .xai:          return "XAI_API_KEY"
        case .deepseek:     return "DEEPSEEK_API_KEY"
        case .ai21:         return "AI21_API_KEY"
        case .groq:         return "GROQ_API_KEY"
        case .cerebras:     return "CEREBRAS_API_KEY"
        case .sambanova:    return "SAMBANOVA_API_KEY"
        case .fireworks:    return "FIREWORKS_API_KEY"
        case .together:     return "TOGETHER_API_KEY"
        case .lepton:       return "LEPTON_API_KEY"
        case .openrouter:   return "OPENROUTER_API_KEY"
        case .deepinfra:    return "DEEPINFRA_API_KEY"
        case .perplexity:   return "PERPLEXITY_API_KEY"
        case .huggingface:  return "HF_TOKEN"
        case .replicate:    return "REPLICATE_API_TOKEN"
        default:            return nil
        }
    }

    /// URL to the provider's API key / dashboard page
    var apiKeyURL: String? {
        switch self {
        case .openai:       return "https://platform.openai.com/api-keys"
        case .anthropic:    return "https://console.anthropic.com/settings/keys"
        case .google:       return "https://aistudio.google.com/apikey"
        case .mistral:      return "https://console.mistral.ai/api-keys"
        case .cohere:       return "https://dashboard.cohere.com/api-keys"
        case .xai:          return "https://console.x.ai"
        case .deepseek:     return "https://platform.deepseek.com/api_keys"
        case .ai21:         return "https://studio.ai21.com/account/api-key"
        case .groq:         return "https://console.groq.com/keys"
        case .cerebras:     return "https://cloud.cerebras.ai"
        case .sambanova:    return "https://cloud.sambanova.ai/apis"
        case .fireworks:    return "https://fireworks.ai/account/api-keys"
        case .together:     return "https://api.together.xyz/settings/api-keys"
        case .lepton:       return "https://dashboard.lepton.ai"
        case .openrouter:   return "https://openrouter.ai/keys"
        case .deepinfra:    return "https://deepinfra.com/dash/api_keys"
        case .perplexity:   return "https://www.perplexity.ai/settings/api"
        case .huggingface:  return "https://huggingface.co/settings/tokens"
        case .replicate:    return "https://replicate.com/account/api-tokens"
        default:            return nil
        }
    }

    enum ClientKind { case ollama, pollinations, anthropic, google, openaiCompatible }

    var clientKind: ClientKind {
        switch self {
        case .ollama:       return .ollama
        case .pollinations: return .pollinations
        case .anthropic:    return .anthropic
        case .google:       return .google
        default:            return .openaiCompatible
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Configuration (persisted JSON file)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct CLIConfig: Codable {
    var apiKeys: [String: String] = [:]
    var models: [String: String] = [:]
    var endpoints: [String: String] = [:]

    /// Returns the API key for a provider: stored key → environment variable → empty
    func apiKey(for p: Provider) -> String {
        let stored = apiKeys[p.displayName] ?? ""
        if !stored.isEmpty { return stored }
        if let envName = p.envKeyName,
           let envValue = ProcessInfo.processInfo.environment[envName],
           !envValue.isEmpty {
            return envValue
        }
        return ""
    }
    func model(for p: Provider) -> String {
        let s = models[p.displayName] ?? ""
        return s.isEmpty ? p.defaultModel : s
    }
    func endpoint(for p: Provider) -> String {
        let s = endpoints[p.displayName] ?? ""
        return s.isEmpty ? p.defaultEndpoint : s
    }

    // Config stored in ~/.config/ai-terminal/config.json (XDG-friendly for brew/choco)
    static var configDir: URL {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/ai-terminal", isDirectory: true)
    }
    static var configFile: URL { configDir.appendingPathComponent("config.json") }

    static func load() -> CLIConfig {
        // Try XDG config first
        if let data = try? Data(contentsOf: configFile),
           let config = try? JSONDecoder().decode(CLIConfig.self, from: data) {
            return config
        }
        // Fallback: read from UserDefaults (shared with GUI app)
        if let data = UserDefaults.standard.data(forKey: "providerConfig"),
           let legacy = try? JSONDecoder().decode(CLIConfig.self, from: data) {
            return legacy
        }
        return CLIConfig()
    }

    func save() {
        try? FileManager.default.createDirectory(at: Self.configDir, withIntermediateDirectories: true)
        if let data = try? JSONEncoder().encode(self) {
            try? data.write(to: Self.configFile, options: .atomic)
        }
        // Also write to UserDefaults for GUI app compat
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "providerConfig")
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Safety Layer
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum SafetyVerdict {
    case safe
    case caution(String)
    case dangerous(String)
}

enum SafetyLayer {
    private static let dangerousPatterns: [(String, String)] = [
        (#"rm\s+-rf\s+/\s*$"#,             "Recursive deletion from root"),
        (#"rm\s+-rf\s+/[^a-zA-Z]"#,        "Recursive deletion from root"),
        (#"rm\s+-rf\s+~\s*$"#,              "Recursive deletion of home directory"),
        (#"rm\s+-rf\s+~/?"#,               "Recursive deletion of home directory"),
        (#"rm\s+-rf\s+\*"#,               "Recursive deletion with wildcard"),
        (#":\(\)\{\s*:\|:&\s*\};:"#,      "Fork bomb"),
        (#"mkfs\."#,                       "Filesystem format"),
        (#"dd\s+if=.*of=/dev/"#,           "Raw disk write"),
        (#">\s*/dev/sd"#,                  "Direct disk overwrite"),
        (#"chmod\s+-R\s+777\s+/"#,         "Unsafe permissions on root"),
    ]

    private static let cautionPatterns: [(String, String)] = [
        (#"sudo\s+"#,                      "Requires elevated privileges"),
        (#"rm\s+-rf"#,                     "Recursive force deletion"),
        (#"rm\s+-r"#,                      "Recursive deletion"),
        (#"git\s+push.*--force"#,          "Force push to remote"),
        (#"git\s+reset\s+--hard"#,         "Hard reset discards changes"),
        (#"drop\s+table"#,                 "Database table deletion"),
        (#"drop\s+database"#,              "Database deletion"),
        (#"truncate\s+table"#,             "Table data deletion"),
        (#"npm\s+publish"#,                "Publishing to npm registry"),
        (#"docker\s+system\s+prune"#,      "Removing Docker resources"),
        (#"kill\s+-9"#,                    "Force killing process"),
        (#"chmod\s+777"#,                  "Overly permissive permissions"),
        (#"curl.*\|.*sh"#,                 "Piping remote script to shell"),
        (#"wget.*\|.*sh"#,                 "Piping remote script to shell"),
    ]

    private static let secretPatterns: [String] = [
        #"(?i)(api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*['"]?[A-Za-z0-9+/=_-]{20,}"#,
        #"(?i)sk-[A-Za-z0-9]{20,}"#,
        #"(?i)ghp_[A-Za-z0-9]{36}"#,
        #"(?i)xox[bpsar]-[A-Za-z0-9-]+"#,
    ]

    static func evaluate(_ command: String) -> SafetyVerdict {
        for (pattern, reason) in dangerousPatterns {
            if command.range(of: pattern, options: .regularExpression) != nil {
                return .dangerous(reason)
            }
        }
        for (pattern, reason) in cautionPatterns {
            if command.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return .caution(reason)
            }
        }
        return .safe
    }

    static func detectSecrets(in text: String) -> Bool {
        secretPatterns.contains { text.range(of: $0, options: .regularExpression) != nil }
    }

    static func printVerdict(_ command: String) {
        switch evaluate(command) {
        case .safe:
            print("  \(C.green)✓ Safe\(C.reset)")
        case .caution(let reason):
            print("  \(C.yellow)⚠ Caution:\(C.reset) \(reason)")
        case .dangerous(let reason):
            print("  \(C.bgRed)\(C.white) ✕ BLOCKED \(C.reset) \(C.red)\(reason)\(C.reset)")
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Memory Store
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct MemoryEntry: Codable {
    let id: String
    let command: String
    let error: String
    let solution: String
    let directory: String
    let timestamp: Date
    let tags: [String]
}

final class MemoryStore {
    private var entries: [MemoryEntry] = []
    private let fileURL: URL

    init() {
        let dir = CLIConfig.configDir
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("memory.json")
        load()
    }

    func remember(command: String, error: String, solution: String, directory: String, tags: [String] = []) {
        let entry = MemoryEntry(
            id: UUID().uuidString, command: command, error: error,
            solution: solution, directory: directory,
            timestamp: Date(), tags: tags
        )
        entries.append(entry)
        if entries.count > 500 { entries.removeFirst(entries.count - 500) }
        save()
    }

    func recall(error: String, limit: Int = 3) -> [MemoryEntry] {
        let keywords = error.lowercased()
            .split(separator: " ")
            .filter { $0.count > 3 }
            .map(String.init)
        return entries
            .map { e -> (MemoryEntry, Int) in
                let haystack = "\(e.command) \(e.error) \(e.solution)".lowercased()
                let score = keywords.filter { haystack.contains($0) }.count
                return (e, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    func recentEntries(limit: Int = 10) -> [MemoryEntry] { Array(entries.suffix(limit)) }
    var count: Int { entries.count }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([MemoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Context Engine
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum ContextEngine {
    struct ProjectInfo {
        var type: String = "Unknown"
        var name: String = ""
        var deps: [String] = []
        var gitBranch: String = ""
        var gitStatus: String = ""
    }

    static func detect() -> ProjectInfo {
        let cwd = FileManager.default.currentDirectoryPath
        let fm = FileManager.default
        var info = ProjectInfo()

        if fm.fileExists(atPath: "\(cwd)/package.json") {
            info.type = "Node.js"
            if let data = fm.contents(atPath: "\(cwd)/package.json"),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                info.name = json["name"] as? String ?? ""
                if let deps = json["dependencies"] as? [String: Any] {
                    info.deps = Array(deps.keys.prefix(15))
                }
            }
        } else if fm.fileExists(atPath: "\(cwd)/Cargo.toml") { info.type = "Rust"
        } else if fm.fileExists(atPath: "\(cwd)/requirements.txt") || fm.fileExists(atPath: "\(cwd)/pyproject.toml") {
            info.type = "Python"
            if let txt = try? String(contentsOfFile: "\(cwd)/requirements.txt", encoding: .utf8) {
                info.deps = txt.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                    .map { $0.components(separatedBy: "==").first ?? $0 }
                    .prefix(15).map { String($0) }
            }
        } else if fm.fileExists(atPath: "\(cwd)/go.mod") { info.type = "Go"
        } else if fm.fileExists(atPath: "\(cwd)/Package.swift") { info.type = "Swift"
        } else if fm.fileExists(atPath: "\(cwd)/Gemfile") { info.type = "Ruby"
        } else if fm.fileExists(atPath: "\(cwd)/pom.xml") { info.type = "Java (Maven)"
        } else if fm.fileExists(atPath: "\(cwd)/build.gradle") || fm.fileExists(atPath: "\(cwd)/build.gradle.kts") {
            info.type = "Java/Kotlin (Gradle)"
        } else if fm.fileExists(atPath: "\(cwd)/Makefile") { info.type = "Make"
        } else if fm.fileExists(atPath: "\(cwd)/CMakeLists.txt") { info.type = "C/C++ (CMake)"
        } else if fm.fileExists(atPath: "\(cwd)/docker-compose.yml") || fm.fileExists(atPath: "\(cwd)/Dockerfile") {
            info.type = "Docker"
        }

        info.gitBranch = shell("git", ["-C", cwd, "branch", "--show-current"])
        if !info.gitBranch.isEmpty {
            info.gitStatus = shell("git", ["-C", cwd, "status", "--short", "--branch"])
        }

        return info
    }

    static func describe() -> String {
        let cwd = FileManager.default.currentDirectoryPath
        let info = detect()
        var parts = ["Dir: \(cwd)"]
        if info.type != "Unknown" { parts.append("Project: \(info.type)") }
        if !info.name.isEmpty { parts.append("Name: \(info.name)") }
        if !info.gitBranch.isEmpty { parts.append("Branch: \(info.gitBranch)") }
        if !info.deps.isEmpty { parts.append("Deps: \(info.deps.prefix(5).joined(separator: ", "))") }
        return parts.joined(separator: " | ")
    }

    private static func shell(_ cmd: String, _ args: [String]) -> String {
        let proc = Process()
        let pipe = Pipe()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        proc.arguments = [cmd] + args
        proc.standardOutput = pipe
        proc.standardError = FileHandle.nullDevice
        do {
            try proc.run()
            proc.waitUntilExit()
            return String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch { return "" }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Command Extraction from AI Responses
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

struct ExtractedCommand {
    let command: String
    let verdict: SafetyVerdict
}

enum CommandExtractor {
    // Finds ```bash ... ``` and ```sh ... ``` blocks
    static func extract(from text: String) -> [ExtractedCommand] {
        var commands: [ExtractedCommand] = []
        let pattern = #"```(?:bash|sh|zsh|shell)?\s*\n([\s\S]*?)```"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: text, range: NSRange(text.startIndex..., in: text))

        for match in matches {
            guard let range = Range(match.range(at: 1), in: text) else { continue }
            let block = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            for line in block.components(separatedBy: "\n") {
                let cmd = line.trimmingCharacters(in: .whitespaces)
                if cmd.isEmpty || cmd.hasPrefix("#") { continue }
                commands.append(ExtractedCommand(command: cmd, verdict: SafetyLayer.evaluate(cmd)))
            }
        }
        return commands
    }

    static func printCommands(_ commands: [ExtractedCommand]) {
        guard !commands.isEmpty else { return }
        print()
        print("\(C.bold)\(C.cyan)── Extracted Commands ──\(C.reset)")
        for (i, cmd) in commands.enumerated() {
            let num = "\(C.dim)[\(i + 1)]\(C.reset)"
            let safety: String
            switch cmd.verdict {
            case .safe:
                safety = "\(C.green)✓\(C.reset)"
            case .caution(let r):
                safety = "\(C.yellow)⚠ \(r)\(C.reset)"
            case .dangerous(let r):
                safety = "\(C.bgRed)\(C.white) BLOCKED \(C.reset) \(C.red)\(r)\(C.reset)"
            }
            print("  \(num) \(C.white)\(cmd.command)\(C.reset)  \(safety)")
        }
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Error Detection
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum ErrorDetector {
    private static let patterns: [String] = [
        #"(?i)^error\b"#, #"(?i)^fatal:"#, #"(?i)^panic:"#,
        #"(?i)command not found"#, #"(?i)permission denied"#,
        #"(?i)no such file"#, #"(?i)segmentation fault"#,
        #"(?i)traceback \(most recent"#, #"(?i)exception:"#,
        #"(?i)errno"#, #"(?i)failed to"#, #"(?i)cannot "# ,
        #"(?i)npm ERR!"#, #"(?i)ENOENT"#, #"(?i)EACCES"#,
        #"(?i)ModuleNotFoundError"#, #"(?i)ImportError"#,
        #"(?i)SyntaxError"#, #"(?i)TypeError"#,
        #"(?i)undefined is not"#, #"(?i)null pointer"#,
        #"(?i)exit code [1-9]"#, #"(?i)exit status [1-9]"#,
        #"(?i)compilation failed"#, #"(?i)build failed"#,
        #"(?i)SIGABRT"#, #"(?i)SIGSEGV"#, #"(?i)SIGKILL"#,
    ]

    static func isError(_ text: String) -> Bool {
        for p in patterns {
            if text.range(of: p, options: .regularExpression) != nil { return true }
        }
        return false
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Prompt Builder
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum PromptBuilder {
    static func systemPrompt(context: String, memory: MemoryStore) -> String {
        var base = """
        You are an expert terminal assistant running on macOS. \
        You help developers understand errors, fix commands, and automate workflows.

        \(context)

        Rules:
        - Be concise and direct
        - Provide executable commands wrapped in ```bash code blocks
        - Explain WHY errors occur, not just how to fix them
        - Warn about dangerous commands (rm -rf, sudo, etc.)
        - Use markdown formatting for clarity
        - Number multi-step solutions
        - If suggesting multiple commands, put each on its own line in the code block
        """

        let recent = memory.recentEntries(limit: 3)
        if !recent.isEmpty {
            base += "\n\nRecent memory (past errors you helped with):\n"
            for e in recent {
                base += "- Command `\(e.command)` error: \(e.error.prefix(80)) → solution: \(e.solution.prefix(80))\n"
            }
        }

        return base
    }

    static func errorPrompt(command: String, output: String) -> String {
        """
        I ran this command:
        ```
        \(command)
        ```

        And got this output:
        ```
        \(String(output.prefix(4000)))
        ```

        What went wrong and how do I fix it? Provide the exact commands to run.
        """
    }

    static func explainPrompt(_ command: String) -> String {
        "Explain this command in detail. Break down each part, flag, and argument. Mention any risks or side effects.\n```\n\(command)\n```"
    }

    static func analyzePrompt(_ text: String) -> String {
        "I got this output from a command. Analyze it — is there an error? What does it mean? How do I fix it?\n```\n\(String(text.prefix(4000)))\n```"
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Streaming Response Accumulator
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Streams tokens to stdout and accumulates the full response
func streamAndCollect(
    provider: Provider, config: CLIConfig,
    prompt: String, systemPrompt: String
) async throws -> String {
    var collected = ""
    let start = Date()

    switch provider.clientKind {
    case .ollama:
        collected = try await streamOllama(config: config, provider: provider, prompt: prompt, system: systemPrompt)
    case .pollinations:
        collected = try await streamPollinations(config: config, provider: provider, prompt: prompt, system: systemPrompt)
    case .anthropic:
        collected = try await streamAnthropic(config: config, provider: provider, prompt: prompt, system: systemPrompt)
    case .google:
        collected = try await streamGoogle(config: config, provider: provider, prompt: prompt, system: systemPrompt)
    case .openaiCompatible:
        collected = try await streamOpenAI(config: config, provider: provider, prompt: prompt, system: systemPrompt)
    }

    let elapsed = String(format: "%.1f", Date().timeIntervalSince(start))
    print("\(C.dim)  ── \(provider.displayName) · \(config.model(for: provider)) · \(elapsed)s ──\(C.reset)")

    // Secret leak check
    if SafetyLayer.detectSecrets(in: collected) {
        print("\(C.bgYellow)\(C.white) ⚠ WARNING \(C.reset) \(C.yellow)AI response may contain an API key or secret. Be careful before sharing.\(C.reset)")
    }

    return collected
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Streaming Clients (return accumulated text)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum CLIError: LocalizedError {
    case invalidURL
    case apiError(String)
    case noProvider
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .apiError(let m): return m
        case .noProvider: return "No provider available. Run with --config to set one up."
        }
    }
}

func streamOpenAI(config: CLIConfig, provider: Provider, prompt: String, system: String) async throws -> String {
    let endpoint = config.endpoint(for: provider)
    let model = config.model(for: provider)
    let key = config.apiKey(for: provider)
    guard let url = URL(string: "\(endpoint)/chat/completions") else { throw CLIError.invalidURL }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 120
    if !key.isEmpty { req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization") }
    if provider == .openrouter { req.setValue("AI Terminal CLI", forHTTPHeaderField: "X-Title") }

    let body: [String: Any] = [
        "model": model, "stream": true,
        "messages": [["role": "system", "content": system], ["role": "user", "content": prompt]]
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, response) = try await URLSession.shared.bytes(for: req)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        throw CLIError.apiError("\(provider.displayName) HTTP \(http.statusCode)")
    }

    var acc = ""
    for try await line in bytes.lines {
        guard line.hasPrefix("data: ") else { continue }
        let payload = String(line.dropFirst(6))
        if payload == "[DONE]" { break }
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else { continue }
        print(content, terminator: "")
        fflush(stdout)
        acc += content
    }
    print()
    return acc
}

func streamOllama(config: CLIConfig, provider: Provider, prompt: String, system: String) async throws -> String {
    let endpoint = config.endpoint(for: provider)
    let model = config.model(for: provider)
    guard let url = URL(string: "\(endpoint)/api/chat") else { throw CLIError.invalidURL }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 120

    let body: [String: Any] = [
        "model": model, "stream": true,
        "messages": [["role": "system", "content": system], ["role": "user", "content": prompt]]
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, _) = try await URLSession.shared.bytes(for: req)
    var acc = ""
    for try await line in bytes.lines {
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else { continue }
        print(content, terminator: "")
        fflush(stdout)
        acc += content
    }
    print()
    return acc
}

func streamAnthropic(config: CLIConfig, provider: Provider, prompt: String, system: String) async throws -> String {
    let endpoint = config.endpoint(for: provider)
    let model = config.model(for: provider)
    let key = config.apiKey(for: provider)
    guard let url = URL(string: "\(endpoint)/v1/messages") else { throw CLIError.invalidURL }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue(key, forHTTPHeaderField: "x-api-key")
    req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    req.timeoutInterval = 120

    let body: [String: Any] = [
        "model": model, "max_tokens": 4096, "stream": true,
        "system": system,
        "messages": [["role": "user", "content": prompt]]
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, response) = try await URLSession.shared.bytes(for: req)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        throw CLIError.apiError("Anthropic HTTP \(http.statusCode)")
    }

    var acc = ""
    for try await line in bytes.lines {
        guard line.hasPrefix("data: ") else { continue }
        let payload = String(line.dropFirst(6))
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
        if let t = json["type"] as? String, t == "content_block_delta",
           let delta = json["delta"] as? [String: Any],
           let text = delta["text"] as? String {
            print(text, terminator: "")
            fflush(stdout)
            acc += text
        }
    }
    print()
    return acc
}

func streamGoogle(config: CLIConfig, provider: Provider, prompt: String, system: String) async throws -> String {
    let model = config.model(for: provider)
    let key = config.apiKey(for: provider)
    guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):streamGenerateContent?alt=sse&key=\(key)")
    else { throw CLIError.invalidURL }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 120

    let body: [String: Any] = [
        "system_instruction": ["parts": [["text": system]]],
        "contents": [["role": "user", "parts": [["text": prompt]]]]
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, response) = try await URLSession.shared.bytes(for: req)
    if let http = response as? HTTPURLResponse, http.statusCode != 200 {
        throw CLIError.apiError("Gemini HTTP \(http.statusCode)")
    }

    var acc = ""
    for try await line in bytes.lines {
        guard line.hasPrefix("data: ") else { continue }
        let payload = String(line.dropFirst(6))
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else { continue }
        print(text, terminator: "")
        fflush(stdout)
        acc += text
    }
    print()
    return acc
}

func streamPollinations(config: CLIConfig, provider: Provider, prompt: String, system: String) async throws -> String {
    let model = config.model(for: provider)
    guard let url = URL(string: "https://text.pollinations.ai/openai/chat/completions") else {
        throw CLIError.invalidURL
    }

    var req = URLRequest(url: url)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.timeoutInterval = 120

    let body: [String: Any] = [
        "model": model, "stream": true,
        "messages": [["role": "system", "content": system], ["role": "user", "content": prompt]]
    ]
    req.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (bytes, _) = try await URLSession.shared.bytes(for: req)
    var acc = ""
    for try await line in bytes.lines {
        guard line.hasPrefix("data: ") else { continue }
        let payload = String(line.dropFirst(6))
        if payload == "[DONE]" { break }
        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String else { continue }
        print(content, terminator: "")
        fflush(stdout)
        acc += content
    }
    print()
    return acc
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Provider Router
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func resolveProvider(_ selected: Provider, config: CLIConfig) async -> Provider {
    guard selected == .auto else { return selected }

    let priority: [Provider] = [
        .ollama, .lmstudio,
        .groq, .cerebras, .sambanova,
        .deepseek,
        .openai, .anthropic, .google, .mistral, .xai,
        .openrouter,
        .together, .fireworks, .lepton, .deepinfra,
        .perplexity, .huggingface, .replicate,
        .cohere, .ai21,
        .pollinations
    ]

    // Check local providers with actual availability ping
    for p in [Provider.ollama, .lmstudio] {
        if await checkLocalAvailability(p, config: config) { return p }
    }

    // For remote providers, just check if API key is set
    for p in priority where !p.isLocal {
        if !p.requiresAPIKey || !config.apiKey(for: p).isEmpty { return p }
    }

    return .pollinations
}

func checkLocalAvailability(_ provider: Provider, config: CLIConfig) async -> Bool {
    let endpoint = config.endpoint(for: provider)
    let checkURL: String
    switch provider {
    case .ollama: checkURL = "\(endpoint)/api/tags"
    case .lmstudio: checkURL = "\(endpoint)/models"
    default: return false
    }
    guard let url = URL(string: checkURL) else { return false }
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.timeoutIntervalForResource = 2
    sessionConfig.timeoutIntervalForRequest = 2
    let session = URLSession(configuration: sessionConfig)
    do {
        let (_, resp) = try await session.data(from: url)
        return (resp as? HTTPURLResponse)?.statusCode == 200
    } catch { return false }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shell Execution (for run command feature)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@discardableResult
func runShellCommand(_ command: String) -> (output: String, exitCode: Int32) {
    let proc = Process()
    let outPipe = Pipe()
    let errPipe = Pipe()
    proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
    proc.arguments = ["-l", "-c", command]
    proc.standardOutput = outPipe
    proc.standardError = errPipe
    proc.currentDirectoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

    do {
        try proc.run()
        proc.waitUntilExit()
        let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        let out = String(data: outData, encoding: .utf8) ?? ""
        let err = String(data: errData, encoding: .utf8) ?? ""
        let combined = out + (err.isEmpty ? "" : "\n" + err)
        return (combined, proc.terminationStatus)
    } catch {
        return ("Failed to execute: \(error.localizedDescription)", 1)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Command History
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

final class CommandHistory {
    private var entries: [String] = []
    private let maxEntries = 200
    private let fileURL: URL

    init() {
        fileURL = CLIConfig.configDir.appendingPathComponent("history.txt")
        load()
    }

    func add(_ entry: String) {
        let trimmed = entry.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if entries.last != trimmed { entries.append(trimmed) }
        if entries.count > maxEntries { entries.removeFirst(entries.count - maxEntries) }
        save()
    }

    var all: [String] { entries }
    var count: Int { entries.count }

    private func load() {
        guard let text = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        entries = text.components(separatedBy: "\n").filter { !$0.isEmpty }
    }

    private func save() {
        let text = entries.joined(separator: "\n")
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Interactive Mode (REPL with all features)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func interactiveMode(provider: Provider, config: CLIConfig, memory: MemoryStore, history: CommandHistory) async {
    let context = ContextEngine.describe()
    let system = PromptBuilder.systemPrompt(context: context, memory: memory)

    printBanner()
    print("\(C.dim)Provider: \(provider.displayName) (\(config.model(for: provider)))\(C.reset)")
    print("\(C.dim)Context: \(context)\(C.reset)")
    print("\(C.dim)Memory: \(memory.count) entries | History: \(history.count) entries\(C.reset)")
    print("\(C.dim)Type \(C.cyan)/help\(C.dim) for commands, \(C.cyan)exit\(C.dim) to quit\(C.reset)")
    print()

    var conversationHistory: [[String: String]] = [
        ["role": "system", "content": system]
    ]

    while true {
        print("\(C.bold)\(C.green)❯\(C.reset) ", terminator: "")
        fflush(stdout)

        guard let rawLine = readLine() else { print(); break }
        let line = rawLine.trimmingCharacters(in: .whitespaces)
        if line.isEmpty { continue }
        if line.lowercased() == "exit" || line.lowercased() == "quit" || line == "/q" { break }

        history.add(line)

        // ── Slash commands ──
        if line.hasPrefix("/") {
            await handleSlashCommand(line, provider: provider, config: config, memory: memory, history: history, context: context)
            continue
        }

        // ── Shell command execution (starts with !) ──
        if line.hasPrefix("!") {
            let cmd = String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
            guard !cmd.isEmpty else { continue }
            await executeWithAI(cmd, provider: provider, config: config, memory: memory, system: system)
            continue
        }

        // ── AI query ──
        print()
        conversationHistory.append(["role": "user", "content": line])

        do {
            let response = try await streamAndCollect(
                provider: provider, config: config,
                prompt: line, systemPrompt: system
            )
            conversationHistory.append(["role": "assistant", "content": response])

            // Extract and display commands
            let commands = CommandExtractor.extract(from: response)
            CommandExtractor.printCommands(commands)

            // Offer to run extracted commands
            if !commands.isEmpty {
                await offerToRun(commands, config: config, provider: provider, memory: memory, system: system)
            }
        } catch {
            stderr("\(C.red)Error: \(error.localizedDescription)\(C.reset)")
        }

        print()
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Slash Commands
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func handleSlashCommand(_ line: String, provider: Provider, config: CLIConfig, memory: MemoryStore, history: CommandHistory, context: String) async {
    let parts = line.split(separator: " ", maxSplits: 1)
    let cmd = String(parts[0]).lowercased()
    let arg = parts.count > 1 ? String(parts[1]) : ""

    switch cmd {
    case "/help", "/h":
        printInteractiveHelp()

    case "/providers", "/p":
        listProviders(config: config)

    case "/context", "/ctx":
        let info = ContextEngine.detect()
        print("\(C.cyan)Project Context\(C.reset)")
        print("  Type:   \(info.type)")
        print("  Name:   \(info.name.isEmpty ? "-" : info.name)")
        print("  Branch: \(info.gitBranch.isEmpty ? "-" : info.gitBranch)")
        if !info.deps.isEmpty { print("  Deps:   \(info.deps.joined(separator: ", "))") }
        if !info.gitStatus.isEmpty { print("  Status:\n\(info.gitStatus.split(separator: "\n").map { "    \($0)" }.joined(separator: "\n"))") }

    case "/memory", "/m":
        let recent = memory.recentEntries(limit: 5)
        if recent.isEmpty {
            print("\(C.dim)No memories stored yet.\(C.reset)")
        } else {
            print("\(C.cyan)Recent Memories (\(memory.count) total)\(C.reset)")
            for e in recent {
                print("  \(C.dim)[\(e.timestamp.formatted())]\(C.reset) \(C.white)\(e.command)\(C.reset)")
                print("  \(C.red)Error:\(C.reset) \(e.error.prefix(60))")
                print("  \(C.green)Fix:\(C.reset) \(e.solution.prefix(60))")
                print()
            }
        }

    case "/history":
        let recent = history.all.suffix(20)
        print("\(C.cyan)Recent History (\(history.count) total)\(C.reset)")
        for (i, h) in recent.enumerated() {
            print("  \(C.dim)\(i + 1).\(C.reset) \(h)")
        }

    case "/safety", "/s":
        if arg.isEmpty {
            print("\(C.dim)Usage: /safety <command>\(C.reset)")
        } else {
            print("  Command: \(C.white)\(arg)\(C.reset)")
            SafetyLayer.printVerdict(arg)
        }

    case "/explain", "/e":
        if arg.isEmpty {
            print("\(C.dim)Usage: /explain <command>\(C.reset)")
        } else {
            let prompt = PromptBuilder.explainPrompt(arg)
            let system = PromptBuilder.systemPrompt(context: context, memory: memory)
            print()
            do {
                _ = try await streamAndCollect(provider: provider, config: config, prompt: prompt, systemPrompt: system)
            } catch {
                stderr("\(C.red)Error: \(error.localizedDescription)\(C.reset)")
            }
        }

    case "/run", "/r":
        if arg.isEmpty {
            print("\(C.dim)Usage: /run <command>\(C.reset)")
        } else {
            let system = PromptBuilder.systemPrompt(context: context, memory: memory)
            await executeWithAI(arg, provider: provider, config: config, memory: memory, system: system)
        }

    case "/clear":
        print("\u{1B}[2J\u{1B}[H")

    case "/version", "/v":
        print("AI Terminal CLI v\(VERSION)")

    case "/config":
        await configWizard()

    default:
        print("\(C.dim)Unknown command. Type /help for available commands.\(C.reset)")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Execute Command with AI Error Analysis
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func executeWithAI(_ command: String, provider: Provider, config: CLIConfig, memory: MemoryStore, system: String) async {
    // Safety check
    let verdict = SafetyLayer.evaluate(command)
    switch verdict {
    case .dangerous(let reason):
        print("\(C.bgRed)\(C.white) ✕ BLOCKED \(C.reset) \(C.red)\(reason)\(C.reset)")
        print("\(C.dim)This command has been blocked for safety.\(C.reset)")
        return
    case .caution(let reason):
        print("\(C.yellow)⚠ Warning:\(C.reset) \(reason)")
        print("Proceed? (y/n) ", terminator: "")
        fflush(stdout)
        guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
            print("\(C.dim)Cancelled.\(C.reset)")
            return
        }
    case .safe:
        break
    }

    // Secret detection in command
    if SafetyLayer.detectSecrets(in: command) {
        print("\(C.bgYellow)\(C.white) ⚠ SECRET \(C.reset) \(C.yellow)This command appears to contain an API key or secret.\(C.reset)")
        print("Proceed? (y/n) ", terminator: "")
        fflush(stdout)
        guard let answer = readLine()?.lowercased(), answer == "y" || answer == "yes" else {
            print("\(C.dim)Cancelled.\(C.reset)")
            return
        }
    }

    print("\(C.dim)$ \(command)\(C.reset)")
    let (output, exitCode) = runShellCommand(command)

    if !output.isEmpty { print(output) }

    if exitCode != 0 || ErrorDetector.isError(output) {
        print("\(C.red)── Exit code: \(exitCode) ──\(C.reset)")

        // Check memory for past solutions
        let recalled = memory.recall(error: output, limit: 2)
        if !recalled.isEmpty {
            print("\(C.cyan)── Past similar errors ──\(C.reset)")
            for r in recalled {
                print("  \(C.dim)\(r.command):\(C.reset) \(r.solution.prefix(80))")
            }
            print()
        }

        print("\(C.blue)Analyzing error with \(provider.displayName)...\(C.reset)")
        print()
        let prompt = PromptBuilder.errorPrompt(command: command, output: output)
        do {
            let response = try await streamAndCollect(
                provider: provider, config: config,
                prompt: prompt, systemPrompt: system
            )

            // Store in memory
            let solutionSummary = String(response.prefix(200))
            memory.remember(command: command, error: String(output.prefix(200)),
                          solution: solutionSummary,
                          directory: FileManager.default.currentDirectoryPath)

            // Extract commands and offer to run
            let commands = CommandExtractor.extract(from: response)
            CommandExtractor.printCommands(commands)
            if !commands.isEmpty {
                await offerToRun(commands, config: config, provider: provider, memory: memory, system: system)
            }
        } catch {
            stderr("\(C.red)AI Error: \(error.localizedDescription)\(C.reset)")
        }
    } else if SafetyLayer.detectSecrets(in: output) {
        print("\(C.bgYellow)\(C.white) ⚠ WARNING \(C.reset) \(C.yellow)Output may contain API keys or secrets!\(C.reset)")
    }
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Run Extracted Commands
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func offerToRun(_ commands: [ExtractedCommand], config: CLIConfig, provider: Provider, memory: MemoryStore, system: String) async {
    let runnableCommands = commands.filter {
        if case .dangerous = $0.verdict { return false }
        return true
    }
    guard !runnableCommands.isEmpty else { return }

    print()
    print("\(C.dim)Run a command? Enter number (or press Enter to skip): \(C.reset)", terminator: "")
    fflush(stdout)
    guard let input = readLine()?.trimmingCharacters(in: .whitespaces),
          let num = Int(input), num > 0, num <= commands.count else { return }

    let selected = commands[num - 1]
    if case .dangerous = selected.verdict {
        print("\(C.red)This command is blocked for safety.\(C.reset)")
        return
    }
    await executeWithAI(selected.command, provider: provider, config: config, memory: memory, system: system)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Config Wizard
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func configWizard() async {
    var config = CLIConfig.load()
    print("\(C.bold)\(C.cyan)AI Terminal CLI Configuration\(C.reset)")
    print("\(C.dim)Config: \(CLIConfig.configFile.path)\(C.reset)")
    print()

    print("\(C.cyan)Currently configured:\(C.reset)")
    var hasAny = false
    for p in Provider.allCases where p != .auto {
        let key = config.apiKey(for: p)
        let storedKey = config.apiKeys[p.displayName] ?? ""
        let fromEnv = storedKey.isEmpty && !key.isEmpty
        if !p.requiresAPIKey || !key.isEmpty {
            let status: String
            if !p.requiresAPIKey {
                status = "\(C.dim)no key needed\(C.reset)"
            } else if fromEnv {
                status = "\(C.green)✓\(C.reset) from env (\(p.envKeyName ?? ""))"
            } else {
                status = "\(C.green)✓\(C.reset) key set"
            }
            let padded = p.displayName.padding(toLength: 16, withPad: " ", startingAt: 0)
            print("  \(padded) \(status)  model: \(C.white)\(config.model(for: p))\(C.reset)")
            hasAny = true
        }
    }
    if !hasAny { print("  \(C.dim)None. Pollinations (free) is always available.\(C.reset)") }

    print()
    print("\(C.dim)Tip: Keys are auto-detected from env vars (e.g. OPENAI_API_KEY)\(C.reset)")
    print("Enter provider name to configure (or \(C.cyan)done\(C.reset)): ", terminator: "")
    fflush(stdout)

    while let input = readLine()?.trimmingCharacters(in: .whitespaces) {
        if input.lowercased() == "done" || input.isEmpty { break }

        guard let p = Provider.allCases.first(where: {
            $0.rawValue.lowercased() == input.lowercased() ||
            $0.displayName.lowercased() == input.lowercased()
        }), p != .auto else {
            print("\(C.red)Unknown provider.\(C.reset) Enter name (or 'done'): ", terminator: "")
            fflush(stdout)
            continue
        }

        if p.requiresAPIKey {
            if let url = p.apiKeyURL {
                print("  \(C.dim)Get key: \(url)\(C.reset)")
            }
            if let envName = p.envKeyName {
                print("  \(C.dim)Or set env var: export \(envName)=your-key\(C.reset)")
            }
            print("  API key for \(p.displayName): ", terminator: "")
            fflush(stdout)
            if let key = readLine()?.trimmingCharacters(in: .whitespaces), !key.isEmpty {
                config.apiKeys[p.displayName] = key
            }
        }
        print("  Model [\(C.dim)\(config.model(for: p))\(C.reset)]: ", terminator: "")
        fflush(stdout)
        if let model = readLine()?.trimmingCharacters(in: .whitespaces), !model.isEmpty {
            config.models[p.displayName] = model
        }
        print("  Endpoint [\(C.dim)\(config.endpoint(for: p))\(C.reset)]: ", terminator: "")
        fflush(stdout)
        if let ep = readLine()?.trimmingCharacters(in: .whitespaces), !ep.isEmpty {
            config.endpoints[p.displayName] = ep
        }
        print("  \(C.green)✓ \(p.displayName) configured\(C.reset)")
        print()
        print("Enter provider name (or 'done'): ", terminator: "")
        fflush(stdout)
    }

    config.save()
    print("\(C.green)✓ Configuration saved to \(CLIConfig.configFile.path)\(C.reset)")
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - List Providers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func listProviders(config: CLIConfig) {
    print("\(C.bold)Available AI Providers (23)\(C.reset)")
    print()

    var currentCat = ""
    for p in Provider.allCases where p != .auto {
        if p.category != currentCat {
            currentCat = p.category
            print("  \(C.cyan)\(C.bold)\(currentCat)\(C.reset)")
        }
        let key = config.apiKey(for: p)
        let storedKey = config.apiKeys[p.displayName] ?? ""
        let fromEnv = storedKey.isEmpty && !key.isEmpty
        let status: String
        if !p.requiresAPIKey {
            status = "\(C.green)● ready\(C.reset)"
        } else if !key.isEmpty && fromEnv {
            status = "\(C.green)● env\(C.reset)  "
        } else if !key.isEmpty {
            status = "\(C.green)● key\(C.reset)  "
        } else {
            status = "\(C.dim)○ no key\(C.reset)"
        }
        let name = p.displayName.padding(toLength: 16, withPad: " ", startingAt: 0)
        let model = config.model(for: p)
        let envHint = p.envKeyName.map { fromEnv ? " \(C.dim)(\($0))\(C.reset)" : "" } ?? ""
        print("    \(name) \(status)  \(C.dim)\(model)\(C.reset)\(envHint)")
    }
    print()
    print("\(C.dim)Keys auto-detected from environment variables (e.g. OPENAI_API_KEY)\(C.reset)")
    print("\(C.dim)Run --config or /config to set API keys.\(C.reset)")
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Banner & Help
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

func printBanner() {
    print("""
    \(C.bold)\(C.cyan)
     ╔═══════════════════════════════════════╗
     ║  \(C.white)AI Terminal CLI\(C.cyan)  v\(VERSION)             ║
     ║  \(C.dim)23 providers · streaming · safe\(C.cyan)      ║
     ╚═══════════════════════════════════════╝
    \(C.reset)
    """)
}

func printInteractiveHelp() {
    print("""

    \(C.bold)\(C.cyan)Commands\(C.reset)
      \(C.white)any text\(C.reset)            Ask the AI a question
      \(C.white)!<command>\(C.reset)           Run a shell command with AI error analysis
      \(C.white)/explain <cmd>\(C.reset)       Explain a command
      \(C.white)/run <cmd>\(C.reset)           Run command with safety check + AI analysis
      \(C.white)/safety <cmd>\(C.reset)        Check if a command is safe
      \(C.white)/providers\(C.reset)           List all AI providers
      \(C.white)/context\(C.reset)             Show detected project context
      \(C.white)/memory\(C.reset)              Show stored error memories
      \(C.white)/history\(C.reset)             Show command history
      \(C.white)/config\(C.reset)              Configure API keys
      \(C.white)/clear\(C.reset)               Clear screen
      \(C.white)/version\(C.reset)             Show version
      \(C.white)exit\(C.reset)                 Quit

    """)
}

func printUsage() {
    print("""
    \(C.bold)AI Terminal CLI\(C.reset) v\(VERSION) — Full-featured AI terminal assistant

    \(C.cyan)USAGE\(C.reset)
      ait [OPTIONS] [QUERY...]
      command 2>&1 | ait --analyze
      ait -i

    \(C.cyan)OPTIONS\(C.reset)
      \(C.white)-i, --interactive\(C.reset)     Interactive REPL with all features
      \(C.white)-a, --analyze\(C.reset)         Analyze piped input as an error
      \(C.white)-e, --explain CMD\(C.reset)     Explain a command in detail
      \(C.white)-r, --run CMD\(C.reset)         Run a command with AI error analysis
      \(C.white)-s, --safety CMD\(C.reset)      Check command safety
      \(C.white)-p, --provider NAME\(C.reset)   Use a specific provider (default: auto)
      \(C.white)--list-providers\(C.reset)      List all 23 providers and status
      \(C.white)--config\(C.reset)              Configure API keys and models
      \(C.white)--memory\(C.reset)              Show stored error memories
      \(C.white)--version\(C.reset)             Show version
      \(C.white)-h, --help\(C.reset)            Show this help

    \(C.cyan)EXAMPLES\(C.reset)
      ait "how do I find large files on macOS?"
      ait --explain "find . -name '*.log' -mtime +30 -delete"
      ait --run "npm run build"
      ait --safety "rm -rf node_modules"
      npm run build 2>&1 | ait --analyze
      ait --provider groq "optimize this SQL query"
      ait -i

    \(C.cyan)INTERACTIVE COMMANDS\(C.reset)
      In interactive mode (-i), prefix shell commands with !
      Use /help for all available slash commands

    \(C.cyan)CONFIG\(C.reset)
      Config: ~/.config/ai-terminal/config.json
      Memory: ~/.config/ai-terminal/memory.json
      History: ~/.config/ai-terminal/history.txt

    """)
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Entry Point
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

@main
struct AITerminalCLI {
    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        // Quick flags (no AI needed)
        if args.contains("--help") || args.contains("-h") { printUsage(); return }
        if args.contains("--version") { print("AI Terminal CLI v\(VERSION)"); return }

        let config = CLIConfig.load()
        let memory = MemoryStore()
        let history = CommandHistory()

        if args.contains("--list-providers") { listProviders(config: config); return }
        if args.contains("--config") { await configWizard(); return }

        if args.contains("--memory") {
            let recent = memory.recentEntries(limit: 10)
            if recent.isEmpty {
                print("\(C.dim)No memories stored yet.\(C.reset)")
            } else {
                print("\(C.bold)Stored Memories (\(memory.count) total)\(C.reset)")
                for e in recent {
                    print("  \(C.dim)[\(e.timestamp.formatted())]\(C.reset)")
                    print("  \(C.white)$ \(e.command)\(C.reset)")
                    print("  \(C.red)Error: \(e.error.prefix(80))\(C.reset)")
                    print("  \(C.green)Fix: \(e.solution.prefix(80))\(C.reset)")
                    print()
                }
            }
            return
        }

        // Parse flags
        var selectedProvider: Provider = .auto
        var analyzeMode = false
        var explainCommand: String?
        var runCommand: String?
        var safetyCommand: String?
        var interactive = false
        var query: [String] = []

        var i = 0
        while i < args.count {
            switch args[i] {
            case "--provider", "-p":
                i += 1
                if i < args.count, let p = Provider(rawValue: args[i].lowercased()) {
                    selectedProvider = p
                } else if i < args.count, let p = Provider.allCases.first(where: {
                    $0.displayName.lowercased() == args[i].lowercased()
                }) {
                    selectedProvider = p
                }
            case "--analyze", "-a":
                analyzeMode = true
            case "--explain", "-e":
                i += 1
                if i < args.count { explainCommand = args[i] }
            case "--run", "-r":
                i += 1
                if i < args.count { runCommand = args[i] }
            case "--safety", "-s":
                i += 1
                if i < args.count { safetyCommand = args[i] }
            case "-i", "--interactive":
                interactive = true
            case "--list-providers", "--config", "--memory", "--version", "--help", "-h":
                break // already handled
            default:
                query.append(args[i])
            }
            i += 1
        }

        // Resolve provider
        let resolved = await resolveProvider(selectedProvider, config: config)
        let context = ContextEngine.describe()
        let system = PromptBuilder.systemPrompt(context: context, memory: memory)

        // ── Safety check mode ──
        if let cmd = safetyCommand {
            print("\(C.bold)Safety Check\(C.reset)")
            print("  Command: \(C.white)\(cmd)\(C.reset)")
            SafetyLayer.printVerdict(cmd)
            if SafetyLayer.detectSecrets(in: cmd) {
                print("  \(C.bgYellow)\(C.white) ⚠ SECRET \(C.reset) \(C.yellow)May contain API key or secret\(C.reset)")
            }
            return
        }

        // ── Explain mode ──
        if let cmd = explainCommand {
            let prompt = PromptBuilder.explainPrompt(cmd)
            print("\(C.dim)Explaining via \(resolved.displayName)...\(C.reset)")
            print()
            do {
                let response = try await streamAndCollect(provider: resolved, config: config, prompt: prompt, systemPrompt: system)
                let commands = CommandExtractor.extract(from: response)
                CommandExtractor.printCommands(commands)
            } catch {
                stderr("\(C.red)Error: \(error.localizedDescription)\(C.reset)")
            }
            return
        }

        // ── Run mode ──
        if let cmd = runCommand {
            await executeWithAI(cmd, provider: resolved, config: config, memory: memory, system: system)
            return
        }

        // ── Analyze piped input ──
        if analyzeMode || (isatty(fileno(stdin)) == 0 && query.isEmpty && !interactive) {
            var input = ""
            while let line = readLine(strippingNewline: false) { input += line }
            if input.isEmpty {
                stderr("\(C.red)No input to analyze. Pipe output or provide a query.\(C.reset)")
                return
            }

            if SafetyLayer.detectSecrets(in: input) {
                print("\(C.bgYellow)\(C.white) ⚠ WARNING \(C.reset) \(C.yellow)Input may contain API keys or secrets\(C.reset)")
            }

            let recalled = memory.recall(error: input, limit: 2)
            if !recalled.isEmpty {
                print("\(C.cyan)── Past similar errors ──\(C.reset)")
                for r in recalled {
                    print("  \(C.dim)\(r.command):\(C.reset) \(r.solution.prefix(80))")
                }
                print()
            }

            let prompt = PromptBuilder.analyzePrompt(input)
            print("\(C.dim)Analyzing via \(resolved.displayName)...\(C.reset)")
            print()
            do {
                let response = try await streamAndCollect(provider: resolved, config: config, prompt: prompt, systemPrompt: system)
                memory.remember(command: "(piped)", error: String(input.prefix(200)),
                              solution: String(response.prefix(200)),
                              directory: FileManager.default.currentDirectoryPath)
                let commands = CommandExtractor.extract(from: response)
                CommandExtractor.printCommands(commands)
            } catch {
                stderr("\(C.red)Error: \(error.localizedDescription)\(C.reset)")
            }
            return
        }

        // ── Interactive mode ──
        if interactive || query.isEmpty {
            await interactiveMode(provider: resolved, config: config, memory: memory, history: history)
            return
        }

        // ── Single query ──
        let prompt = query.joined(separator: " ")
        history.add(prompt)
        print("\(C.dim)via \(resolved.displayName) (\(config.model(for: resolved)))\(C.reset)")
        print()
        do {
            let response = try await streamAndCollect(provider: resolved, config: config, prompt: prompt, systemPrompt: system)
            let commands = CommandExtractor.extract(from: response)
            CommandExtractor.printCommands(commands)
        } catch {
            stderr("\(C.red)Error: \(error.localizedDescription)\(C.reset)")
        }
    }
}
