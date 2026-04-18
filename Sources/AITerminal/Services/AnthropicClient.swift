import Foundation

/// Client for the Anthropic Messages API (Claude models).
final class AnthropicClient: AIClient {
    let providerType: AIProviderType = .anthropic
    private let apiKey: String
    private let model: String
    private let baseURL: String

    init(apiKey: String, model: String, baseURL: String = "https://api.anthropic.com") {
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func checkAvailability() async -> Bool {
        !apiKey.isEmpty
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        let request = try buildRequest(prompt: prompt, systemPrompt: systemPrompt, stream: false)
        let (data, _) = try await URLSession.shared.data(for: request)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let text = content.first?["text"] as? String else {
            throw AIError.invalidResponse
        }
        return text
    }

    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try self.buildRequest(
                        prompt: prompt, systemPrompt: systemPrompt, stream: true
                    )
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)

                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                            .trimmingCharacters(in: .whitespaces)
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data)
                                  as? [String: Any] else { continue }

                        let eventType = json["type"] as? String ?? ""
                        if eventType == "content_block_delta",
                           let delta = json["delta"] as? [String: Any],
                           let text = delta["text"] as? String {
                            continuation.yield(text)
                        }
                        if eventType == "message_stop" { break }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func buildRequest(
        prompt: String,
        systemPrompt: String,
        stream: Bool
    ) throws -> URLRequest {
        guard let url = URL(string: "\(baseURL)/v1/messages") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 60

        var body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "system": systemPrompt,
            "messages": [
                ["role": "user", "content": prompt]
            ]
        ]
        if stream { body["stream"] = true }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
