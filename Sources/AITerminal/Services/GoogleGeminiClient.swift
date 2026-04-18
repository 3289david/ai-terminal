import Foundation

/// Client for the Google Gemini API.
final class GoogleGeminiClient: AIClient {
    let providerType: AIProviderType = .google
    private let apiKey: String
    private let model: String

    init(apiKey: String, model: String) {
        self.apiKey = apiKey
        self.model = model
    }

    func checkAvailability() async -> Bool {
        !apiKey.isEmpty
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        let url = try buildURL(stream: false)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "contents": [["role": "user", "parts": [["text": prompt]]]],
            "systemInstruction": ["parts": [["text": systemPrompt]]]
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw AIError.invalidResponse
        }
        return text
    }

    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let url = try self.buildURL(stream: true)

                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.timeoutInterval = 60

                    let body: [String: Any] = [
                        "contents": [["role": "user", "parts": [["text": prompt]]]],
                        "systemInstruction": ["parts": [["text": systemPrompt]]]
                    ]
                    request.httpBody = try JSONSerialization.data(withJSONObject: body)

                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                            .trimmingCharacters(in: .whitespaces)
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data)
                                  as? [String: Any],
                              let candidates = json["candidates"] as? [[String: Any]],
                              let content = candidates.first?["content"] as? [String: Any],
                              let parts = content["parts"] as? [[String: Any]],
                              let text = parts.first?["text"] as? String else {
                            continue
                        }
                        continuation.yield(text)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    // MARK: - Private

    private func buildURL(stream: Bool) throws -> URL {
        let base = "https://generativelanguage.googleapis.com/v1beta/models/\(model)"
        let action = stream ? "streamGenerateContent" : "generateContent"
        let queryItems = stream ? "alt=sse&key=\(apiKey)" : "key=\(apiKey)"
        guard let url = URL(string: "\(base):\(action)?\(queryItems)") else {
            throw AIError.invalidURL
        }
        return url
    }
}
