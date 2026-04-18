import Foundation

final class PollinationsClient: AIClient {
    let providerType: AIProviderType = .pollinations
    private let model: String

    init(model: String = "openai") {
        self.model = model
    }

    func checkAvailability() async -> Bool {
        guard let url = URL(string: "https://text.pollinations.ai/") else { return false }
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        guard let url = URL(string: "https://text.pollinations.ai/") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        let body: [String: Any] = [
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ],
            "model": model
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        guard let text = String(data: data, encoding: .utf8), !text.isEmpty else {
            throw AIError.invalidResponse
        }
        return text
    }

    func stream(prompt: String, systemPrompt: String) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // Pollinations does not support SSE natively; simulate streaming
                    let result = try await complete(prompt: prompt, systemPrompt: systemPrompt)
                    let words = result.split(separator: " ")
                    for (index, word) in words.enumerated() {
                        let token = index < words.count - 1 ? String(word) + " " : String(word)
                        continuation.yield(token)
                        try await Task.sleep(nanoseconds: 15_000_000) // 15 ms
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
}
