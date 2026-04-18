import Foundation

final class MemoryStore {
    private let storageURL: URL
    private var entries: [MemoryEntry] = []

    struct MemoryEntry: Codable, Identifiable {
        let id: UUID
        let command: String
        let error: String
        let solution: String
        let directory: String
        let timestamp: Date
        let tags: [String]
    }

    init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        storageURL = appSupport.appendingPathComponent("AITerminal", isDirectory: true)
        try? FileManager.default.createDirectory(at: storageURL, withIntermediateDirectories: true)
        load()
    }

    // MARK: - Public

    func remember(command: String, error: String, solution: String,
                  directory: String, tags: [String] = []) {
        let entry = MemoryEntry(
            id: UUID(), command: command, error: error,
            solution: solution, directory: directory,
            timestamp: Date(), tags: tags
        )
        entries.append(entry)
        save()
    }

    /// Find past entries similar to the given error text (keyword overlap).
    func recall(error: String, limit: Int = 3) -> [MemoryEntry] {
        let keywords = error.lowercased()
            .split(separator: " ")
            .filter { $0.count > 3 }
            .map(String.init)

        return entries
            .map { entry -> (MemoryEntry, Int) in
                let haystack = "\(entry.command) \(entry.error) \(entry.solution)".lowercased()
                let score = keywords.filter { haystack.contains($0) }.count
                return (entry, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(limit)
            .map(\.0)
    }

    func recentEntries(limit: Int = 10) -> [MemoryEntry] {
        Array(entries.suffix(limit))
    }

    // MARK: - Persistence

    private func load() {
        let url = storageURL.appendingPathComponent("memory.json")
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([MemoryEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        let url = storageURL.appendingPathComponent("memory.json")
        guard let data = try? JSONEncoder().encode(entries) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
