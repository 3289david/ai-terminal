import Foundation

struct ProjectInfo {
    var type: String = "Unknown"
    var name: String = ""
    var dependencies: [String] = []
    var gitBranch: String = ""
    var gitStatus: String = ""
}

final class ContextEngine {

    // MARK: - Public

    static func analyze(directory: String) async -> ProjectInfo {
        var info = ProjectInfo()
        let fm = FileManager.default

        // Detect project type & read metadata
        if fm.fileExists(atPath: "\(directory)/package.json") {
            info.type = "Node.js"
            if let data = fm.contents(atPath: "\(directory)/package.json"),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                info.name = json["name"] as? String ?? ""
                if let deps = json["dependencies"] as? [String: Any] {
                    info.dependencies = Array(deps.keys.prefix(20))
                }
            }
        } else if fm.fileExists(atPath: "\(directory)/Cargo.toml") {
            info.type = "Rust"
        } else if fm.fileExists(atPath: "\(directory)/requirements.txt") {
            info.type = "Python"
            if let text = try? String(contentsOfFile: "\(directory)/requirements.txt", encoding: .utf8) {
                let lines = text.components(separatedBy: .newlines)
                    .filter { !$0.isEmpty && !$0.hasPrefix("#") }
                info.dependencies = Array(lines.prefix(20))
            }
        } else if fm.fileExists(atPath: "\(directory)/go.mod") {
            info.type = "Go"
        } else if fm.fileExists(atPath: "\(directory)/Package.swift") {
            info.type = "Swift"
        } else if fm.fileExists(atPath: "\(directory)/Gemfile") {
            info.type = "Ruby"
        } else if fm.fileExists(atPath: "\(directory)/pom.xml") {
            info.type = "Java (Maven)"
        } else if fm.fileExists(atPath: "\(directory)/build.gradle") ||
                  fm.fileExists(atPath: "\(directory)/build.gradle.kts") {
            info.type = "Java/Kotlin (Gradle)"
        }

        // Git info
        if fm.fileExists(atPath: "\(directory)/.git") {
            info.gitBranch = await shell("git", args: ["-C", directory, "branch", "--show-current"])
            info.gitStatus = await shell("git", args: ["-C", directory, "status", "--short"])
        }

        return info
    }

    static func describe(directory: String) async -> String {
        let info = await analyze(directory: directory)
        var parts: [String] = []
        if info.type != "Unknown" { parts.append("Project: \(info.type)") }
        if !info.name.isEmpty { parts.append("Name: \(info.name)") }
        if !info.gitBranch.isEmpty { parts.append("Branch: \(info.gitBranch)") }
        if !info.dependencies.isEmpty {
            parts.append("Deps: \(info.dependencies.prefix(5).joined(separator: ", "))")
        }
        return parts.joined(separator: " | ")
    }

    // MARK: - Private

    private static func shell(_ cmd: String, args: [String]) async -> String {
        await withCheckedContinuation { cont in
            let proc = Process()
            let pipe = Pipe()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            proc.arguments = [cmd] + args
            proc.standardOutput = pipe
            proc.standardError = FileHandle.nullDevice
            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let out = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                cont.resume(returning: out)
            } catch {
                cont.resume(returning: "")
            }
        }
    }
}
