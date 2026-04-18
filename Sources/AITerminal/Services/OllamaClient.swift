import Foundation

final class OllamaClient: AIClient {
    let providerType: AIProviderType = .ollama
    private let endpoint: String
    private let model: String

    init(endpoint: String, model: String) {
        self.endpoint = endpoint.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.model = model
    }

    func checkAvailability() async -> Bool {
        guard let url = URL(string: "\(endpoint)/api/tags") else { return false }
        do {
            // Short timeout so "Connection refused" doesn't hang
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForResource = 3
            config.timeoutIntervalForRequest = 3
            let session = URLSession(configuration: config)
            let (_, response) = try await session.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            // Silently returns false -- Ollama not running is normal
            return false
        }
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: "\(endpoint)/api/generate") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 120

        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "system": systemPrompt,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let response = json?["response"] as? String else {
            throw AIError.invalidResponse
        }
        return response
    }

    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let url = URL(string: "\(endpoint)/api/generate") else {
                        continuation.finish(throwing: AIError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 120

                    let body: [String: Any] = [
                        "model": model,
                        "prompt": prompt,
                        "system": systemPrompt,
                        "stream": true
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard let data = line.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let token = json["response"] as? String else { continue }
                        continuation.yield(token)
                        if json["done"] as? Bool == true { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
