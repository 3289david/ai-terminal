import Foundation

// MARK: - Safety Verdict

enum SafetyVerdict {
    case safe
    case caution(reason: String)
    case dangerous(reason: String)
}

// MARK: - Safety Layer

final class SafetyLayer {

    // ── Dangerous (blocked) ─────────────────────────────────
    private static let dangerousPatterns: [(pattern: String, reason: String)] = [
        (#"rm\s+-rf\s+/"#,                "Recursive deletion from root directory"),
        (#"rm\s+-rf\s+~"#,                "Recursive deletion of home directory"),
        (#"rm\s+-rf\s+\*"#,               "Recursive deletion with wildcard"),
        (#":\(\)\{\s*:\|:&\s*\};:"#,      "Fork bomb detected"),
        (#"mkfs\."#,                       "Filesystem formatting command"),
        (#"dd\s+if=.*of=/dev/"#,           "Raw disk write operation"),
        (#">\s*/dev/sd"#,                  "Direct disk overwrite"),
        (#"chmod\s+-R\s+777\s+/"#,         "Unsafe permissions on root"),
    ]

    // ── Caution (warn) ──────────────────────────────────────
    private static let cautionPatterns: [(pattern: String, reason: String)] = [
        (#"sudo\s+"#,                      "Requires elevated privileges"),
        (#"rm\s+-rf"#,                     "Recursive force deletion"),
        (#"rm\s+-r"#,                      "Recursive deletion"),
        (#"git\s+push.*--force"#,          "Force pushing to remote"),
        (#"git\s+reset\s+--hard"#,         "Hard reset discards changes"),
        (#"drop\s+table"#,                 "Database table deletion"),
        (#"drop\s+database"#,              "Database deletion"),
        (#"truncate\s+table"#,             "Table data deletion"),
        (#"npm\s+publish"#,                "Publishing to npm registry"),
        (#"docker\s+system\s+prune"#,      "Removing Docker resources"),
        (#"kill\s+-9"#,                    "Force killing a process"),
        (#"chmod\s+777"#,                  "Overly permissive file permissions"),
        (#"curl.*\|.*sh"#,                 "Piping remote script to shell"),
        (#"wget.*\|.*sh"#,                 "Piping remote script to shell"),
    ]

    // ── API key patterns ────────────────────────────────────
    private static let secretPatterns: [String] = [
        #"(?i)(api[_-]?key|secret[_-]?key|access[_-]?token|auth[_-]?token)\s*[=:]\s*['"]?[A-Za-z0-9+/=_-]{20,}"#,
        #"(?i)sk-[A-Za-z0-9]{20,}"#,
        #"(?i)ghp_[A-Za-z0-9]{36}"#,
        #"(?i)xox[bpsar]-[A-Za-z0-9-]+"#,
    ]

    // MARK: - Evaluate

    static func evaluate(command: String) -> SafetyVerdict {
        for (pattern, reason) in dangerousPatterns {
            if command.range(of: pattern, options: .regularExpression) != nil {
                return .dangerous(reason: reason)
            }
        }
        for (pattern, reason) in cautionPatterns {
            if command.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil {
                return .caution(reason: reason)
            }
        }
        return .safe
    }

    // MARK: - Secret Detection

    static func detectSecretLeak(in text: String) -> Bool {
        secretPatterns.contains { pattern in
            text.range(of: pattern, options: .regularExpression) != nil
        }
    }
}
