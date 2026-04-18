import Foundation

@Observable
final class AIRouter {
    private var clients: [AIProviderType: AIClient] = [:]
    private(set) var availability: [AIProviderType: Bool] = [:]

    // MARK: - Configuration

    func configure(with config: ProviderConfig) {
        clients.removeAll()

        for provider in AIProviderType.allCases where provider != .auto {
            let key = config.apiKey(for: provider)
            let model = config.model(for: provider)
            let endpoint = config.endpoint(for: provider)

            // Skip providers that need an API key but have none
            if provider.requiresAPIKey && key.isEmpty { continue }

            switch provider.clientKind {
            case .ollama:
                clients[provider] = OllamaClient(endpoint: endpoint, model: model)

            case .pollinations:
                clients[provider] = PollinationsClient(model: model)

            case .anthropic:
                clients[provider] = AnthropicClient(
                    apiKey: key, model: model, baseURL: endpoint
                )

            case .google:
                clients[provider] = GoogleGeminiClient(apiKey: key, model: model)

            case .openaiCompatible:
                clients[provider] = OpenAICompatibleClient(
                    provider: provider,
                    apiKey: key,
                    model: model,
                    baseURL: endpoint
                )
            }
        }
    }

    // MARK: - Availability

    func refreshAvailability() async {
        await withTaskGroup(of: (AIProviderType, Bool).self) { group in
            for (type, client) in clients {
                group.addTask {
                    let ok = await client.checkAvailability()
                    return (type, ok)
                }
            }
            for await (type, ok) in group {
                availability[type] = ok
            }
        }
    }

    func isAvailable(_ provider: AIProviderType) -> Bool {
        if provider == .auto { return true }
        return availability[provider] ?? false
    }

    // MARK: - Routing

    /// Resolve `.auto` to the best concrete provider.
    /// Priority: Local > Fast free-tier > Cheap cloud > Premium > Aggregator > Free fallback
    func resolveProvider(_ selected: AIProviderType) -> AIProviderType {
        guard selected == .auto else { return selected }

        let priority: [AIProviderType] = [
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

        for p in priority {
            if availability[p] == true { return p }
        }
        return .pollinations
    }

    // MARK: - Completion

    func complete(
        prompt: String,
        systemPrompt: String,
        provider: AIProviderType
    ) async throws -> (String, AIProviderType) {
        let resolved = resolveProvider(provider)
        guard let client = clients[resolved] else {
            throw AIError.providerUnavailable
        }
        let response = try await client.complete(prompt: prompt, systemPrompt: systemPrompt)
        return (response, resolved)
    }

    // MARK: - Streaming

    func stream(
        prompt: String,
        systemPrompt: String,
        provider: AIProviderType
    ) -> (AsyncThrowingStream<String, Error>, AIProviderType) {
        let resolved = resolveProvider(provider)
        guard let client = clients[resolved] else {
            let errStream = AsyncThrowingStream<String, Error> {
                $0.finish(throwing: AIError.providerUnavailable)
            }
            return (errStream, resolved)
        }
        return (client.stream(prompt: prompt, systemPrompt: systemPrompt), resolved)
    }
}
