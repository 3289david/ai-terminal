import Foundation

/// Generic client for all OpenAI-compatible chat completion APIs.
/// Works with: OpenAI, Mistral, Groq, Together, Fireworks, DeepSeek, xAI,
/// Cerebras, SambaNova, Lepton, OpenRouter, DeepInfra, Perplexity,
/// HuggingFace, Replicate, AI21, Cohere, LM Studio.
final class OpenAICompatibleClient: AIClient {
    let providerType: AIProviderType
    private let apiKey: String
    private let model: String
    private let baseURL: String
    private let extraHeaders: [String: String]

    init(
        provider: AIProviderType,
        apiKey: String,
        model: String,
        baseURL: String,
        extraHeaders: [String: String] = [:]
    ) {
        self.providerType = provider
        self.apiKey = apiKey
        self.model = model
        self.baseURL = baseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        self.extraHeaders = extraHeaders
    }

    func checkAvailability() async -> Bool {
        if providerType.isLocal {
            guard let url = URL(string: "\(baseURL)/models") else { return false }
            let config = URLSessionConfiguration.ephemeral
            config.timeoutIntervalForResource = 3
            config.timeoutIntervalForRequest = 3
            let session = URLSession(configuration: config)
            do {
                let (_, resp) = try await session.data(from: url)
                return (resp as? HTTPURLResponse)?.statusCode == 200
            } catch {
                return false
            }
        }
        return !apiKey.isEmpty || !providerType.requiresAPIKey
    }

    func complete(prompt: String, systemPrompt: String) async throws -> String {
        let request = try buildRequest(prompt: prompt, systemPrompt: systemPrompt, stream: false)
        let (data, _) = try await URLSession.shared.data(for: request)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
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
                    let request = try self.buildRequest(
                        prompt: prompt, systemPrompt: systemPrompt, stream: true
                    )
                    let (bytes, _) = try await URLSession.shared.bytes(for: request)
                    for try await line in bytes.lines {
                        guard line.hasPrefix("data: ") else { continue }
                        let payload = String(line.dropFirst(6))
                            .trimmingCharacters(in: .whitespaces)
                        if payload == "[DONE]" { break }
                        guard let data = payload.data(using: .utf8),
                              let json = try? JSONSerialization.jsonObject(with: data)
                                  as? [String: Any],
                              let choices = json["choices"] as? [[String: Any]],
                              let delta = choices.first?["delta"] as? [String: Any],
                              let content = delta["content"] as? String else {
                            continue
                        }
                        continuation.yield(content)
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
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60

        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        for (key, value) in extraHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }

        if providerType == .openrouter {
            request.setValue("AI Terminal", forHTTPHeaderField: "X-Title")
        }

        var body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": prompt]
            ]
        ]
        if stream { body["stream"] = true }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }
}
