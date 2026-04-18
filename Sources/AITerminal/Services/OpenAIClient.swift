import Foundation

final class OpenAIClient: AIClient {
    let providerType: AIProviderType = .openai
    private let apiKey: String
    private let model: String
    private let baseURL: String

    init(apiKey: String, model: String, baseURL: String = "https://api.openai.com/v1") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL
    }

    func checkAvailability() async -> Bool {
        !apiKey.isEmpty
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        guard !apiKey.isEmpty else { throw AIError.apiKeyMissing }
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        return content
    }

    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    guard !apiKey.isEmpty else {
                        continuation.finish(throwing: AIError.apiKeyMissing)
                        return
                    }
                    guard let url = URL(string: "\(baseURL)/chat/completions") else {
                        continuation.finish(throwing: AIError.invalidURL)
                        return
                    }

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                    request.timeoutInterval = 60

                    let body: [String: Any] = [
                        "model": model,
                        "messages": [
                            ["role": "system", "content": systemPrompt],
                            ["role": "user", "content": prompt]
                        ],
                        "stream": true
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                        if payload.trimmingCharacters(in: .whitespaces) == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else { continue }
                        continuation.yield(content)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
