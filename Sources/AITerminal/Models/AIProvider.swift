import Foundation

// MARK: - Provider Category

enum ProviderCategory: String, CaseIterable {
    case local      = "Local"
    case free       = "Free"
    case cloud      = "Cloud"
    case inference  = "Fast Inference"
    case aggregator = "Aggregator"
}

// MARK: - AI Provider (23 providers + auto)

enum AIProviderType: String, CaseIterable, Codable, Identifiable {
    case auto         = "Auto"

    // Local
    case ollama       = "Ollama"
    case lmstudio     = "LM Studio"

    // Free
    case pollinations = "Pollinations"

    // Major Cloud
    case openai       = "OpenAI"
    case anthropic    = "Anthropic"
    case google       = "Google Gemini"
    case mistral      = "Mistral"
    case cohere       = "Cohere"
    case xai          = "xAI"
    case deepseek     = "DeepSeek"
    case ai21         = "AI21"

    // Fast Inference
    case groq         = "Groq"
    case cerebras     = "Cerebras"
    case sambanova    = "SambaNova"
    case fireworks    = "Fireworks"
    case together     = "Together"
    case lepton       = "Lepton"

    // Aggregators
    case openrouter   = "OpenRouter"
    case deepinfra    = "DeepInfra"
    case perplexity   = "Perplexity"
    case huggingface  = "HuggingFace"
    case replicate    = "Replicate"

    var id: String { rawValue }

    var category: ProviderCategory {
        switch self {
        case .auto:                                            return .cloud
        case .ollama, .lmstudio:                               return .local
        case .pollinations:                                    return .free
        case .openai, .anthropic, .google, .mistral,
             .cohere, .xai, .deepseek, .ai21:                 return .cloud
        case .groq, .cerebras, .sambanova,
             .fireworks, .together, .lepton:                   return .inference
        case .openrouter, .deepinfra, .perplexity,
             .huggingface, .replicate:                         return .aggregator
        }
    }

    var icon: String {
        switch self {
        case .auto:         return "wand.and.stars"
        case .ollama:       return "desktopcomputer"
        case .lmstudio:     return "laptopcomputer"
        case .pollinations: return "leaf.fill"
        case .openai:       return "brain"
        case .anthropic:    return "shield.fill"
        case .google:       return "globe"
        case .mistral:      return "wind"
        case .cohere:       return "link"
        case .xai:          return "bolt.circle.fill"
        case .deepseek:     return "magnifyingglass"
        case .ai21:         return "textformat"
        case .groq:         return "hare.fill"
        case .cerebras:     return "cpu"
        case .sambanova:    return "memorychip"
        case .fireworks:    return "flame.fill"
        case .together:     return "person.2.fill"
        case .lepton:       return "atom"
        case .openrouter:   return "arrow.triangle.branch"
        case .deepinfra:    return "server.rack"
        case .perplexity:   return "text.magnifyingglass"
        case .huggingface:  return "face.smiling"
        case .replicate:    return "square.on.square"
        }
    }

    var subtitle: String {
        switch self {
        case .auto:         return "Best available provider"
        case .ollama:       return "Local, free, offline"
        case .lmstudio:     return "Local, free, offline"
        case .pollinations: return "Free, no API key"
        case .openai:       return "GPT-4o, o1, o3"
        case .anthropic:    return "Claude Sonnet, Opus, Haiku"
        case .google:       return "Gemini 2.0 Flash, Pro"
        case .mistral:      return "Mistral Large, Codestral"
        case .cohere:       return "Command R+"
        case .xai:          return "Grok-2, Grok-3"
        case .deepseek:     return "DeepSeek V3, R1"
        case .ai21:         return "Jamba 1.5"
        case .groq:         return "Ultra-fast inference"
        case .cerebras:     return "Ultra-fast inference"
        case .sambanova:    return "Fast inference"
        case .fireworks:    return "Fast inference"
        case .together:     return "100+ open models"
        case .lepton:       return "Serverless AI"
        case .openrouter:   return "200+ models, one API"
        case .deepinfra:    return "Fast open models"
        case .perplexity:   return "Search-augmented AI"
        case .huggingface:  return "Open-source models"
        case .replicate:    return "Run any model"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .auto:         return ""
        case .ollama:       return "http://localhost:11434"
        case .lmstudio:     return "http://localhost:1234/v1"
        case .pollinations: return "https://text.pollinations.ai"
        case .openai:       return "https://api.openai.com/v1"
        case .anthropic:    return "https://api.anthropic.com"
        case .google:       return "https://generativelanguage.googleapis.com/v1beta"
        case .mistral:      return "https://api.mistral.ai/v1"
        case .cohere:       return "https://api.cohere.com/compatibility/v1"
        case .xai:          return "https://api.x.ai/v1"
        case .deepseek:     return "https://api.deepseek.com"
        case .ai21:         return "https://api.ai21.com/studio/v1"
        case .groq:         return "https://api.groq.com/openai/v1"
        case .cerebras:     return "https://api.cerebras.ai/v1"
        case .sambanova:    return "https://api.sambanova.ai/v1"
        case .fireworks:    return "https://api.fireworks.ai/inference/v1"
        case .together:     return "https://api.together.xyz/v1"
        case .lepton:       return "https://llama3-1-405b.lepton.run/api/v1"
        case .openrouter:   return "https://openrouter.ai/api/v1"
        case .deepinfra:    return "https://api.deepinfra.com/v1/openai"
        case .perplexity:   return "https://api.perplexity.ai"
        case .huggingface:  return "https://api-inference.huggingface.co/v1"
        case .replicate:    return "https://api.replicate.com/v1"
        }
    }

    var defaultModel: String {
        switch self {
        case .auto:         return ""
        case .ollama:       return "llama3"
        case .lmstudio:     return "local-model"
        case .pollinations: return "openai"
        case .openai:       return "gpt-4o"
        case .anthropic:    return "claude-sonnet-4-20250514"
        case .google:       return "gemini-2.0-flash"
        case .mistral:      return "mistral-large-latest"
        case .cohere:       return "command-r-plus"
        case .xai:          return "grok-2"
        case .deepseek:     return "deepseek-chat"
        case .ai21:         return "jamba-1.5-large"
        case .groq:         return "llama-3.3-70b-versatile"
        case .cerebras:     return "llama-3.3-70b"
        case .sambanova:    return "Meta-Llama-3.3-70B-Instruct"
        case .fireworks:    return "accounts/fireworks/models/llama-v3p3-70b-instruct"
        case .together:     return "meta-llama/Llama-3.3-70B-Instruct-Turbo"
        case .lepton:       return "llama3-1-405b"
        case .openrouter:   return "anthropic/claude-sonnet-4"
        case .deepinfra:    return "meta-llama/Llama-3.3-70B-Instruct"
        case .perplexity:   return "sonar-pro"
        case .huggingface:  return "meta-llama/Llama-3.3-70B-Instruct"
        case .replicate:    return "meta/llama-3.3-70b-instruct"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .auto, .ollama, .lmstudio, .pollinations: return false
        default: return true
        }
    }

    var isLocal: Bool {
        self == .ollama || self == .lmstudio
    }

    /// Environment variable name to check for API key fallback
    var envKeyName: String? {
        switch self {
        case .openai:       return "OPENAI_API_KEY"
        case .anthropic:    return "ANTHROPIC_API_KEY"
        case .google:       return "GOOGLE_API_KEY"
        case .mistral:      return "MISTRAL_API_KEY"
        case .cohere:       return "COHERE_API_KEY"
        case .xai:          return "XAI_API_KEY"
        case .deepseek:     return "DEEPSEEK_API_KEY"
        case .ai21:         return "AI21_API_KEY"
        case .groq:         return "GROQ_API_KEY"
        case .cerebras:     return "CEREBRAS_API_KEY"
        case .sambanova:    return "SAMBANOVA_API_KEY"
        case .fireworks:    return "FIREWORKS_API_KEY"
        case .together:     return "TOGETHER_API_KEY"
        case .lepton:       return "LEPTON_API_KEY"
        case .openrouter:   return "OPENROUTER_API_KEY"
        case .deepinfra:    return "DEEPINFRA_API_KEY"
        case .perplexity:   return "PERPLEXITY_API_KEY"
        case .huggingface:  return "HF_TOKEN"
        case .replicate:    return "REPLICATE_API_TOKEN"
        default:            return nil
        }
    }

    /// URL to the provider's API key / dashboard page
    var apiKeyURL: String? {
        switch self {
        case .openai:       return "https://platform.openai.com/api-keys"
        case .anthropic:    return "https://console.anthropic.com/settings/keys"
        case .google:       return "https://aistudio.google.com/apikey"
        case .mistral:      return "https://console.mistral.ai/api-keys"
        case .cohere:       return "https://dashboard.cohere.com/api-keys"
        case .xai:          return "https://console.x.ai"
        case .deepseek:     return "https://platform.deepseek.com/api_keys"
        case .ai21:         return "https://studio.ai21.com/account/api-key"
        case .groq:         return "https://console.groq.com/keys"
        case .cerebras:     return "https://cloud.cerebras.ai"
        case .sambanova:    return "https://cloud.sambanova.ai/apis"
        case .fireworks:    return "https://fireworks.ai/account/api-keys"
        case .together:     return "https://api.together.xyz/settings/api-keys"
        case .lepton:       return "https://dashboard.lepton.ai"
        case .openrouter:   return "https://openrouter.ai/keys"
        case .deepinfra:    return "https://deepinfra.com/dash/api_keys"
        case .perplexity:   return "https://www.perplexity.ai/settings/api"
        case .huggingface:  return "https://huggingface.co/settings/tokens"
        case .replicate:    return "https://replicate.com/account/api-tokens"
        default:            return nil
        }
    }

    enum ClientKind {
        case ollama
        case pollinations
        case anthropic
        case google
        case openaiCompatible
    }

    var clientKind: ClientKind {
        switch self {
        case .ollama:       return .ollama
        case .pollinations: return .pollinations
        case .anthropic:    return .anthropic
        case .google:       return .google
        default:            return .openaiCompatible
        }
    }
}

// MARK: - Execution Mode

enum ExecutionMode: String, CaseIterable, Codable, Identifiable {
    case safe      = "Safe"
    case assisted  = "Assisted"
    case autopilot = "Autopilot"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .safe:      return Icons.safe
        case .assisted:  return Icons.assisted
        case .autopilot: return Icons.autopilot
        }
    }

    var subtitle: String {
        switch self {
        case .safe:      return "AI recommends only, you execute"
        case .assisted:  return "AI suggests with run buttons"
        case .autopilot: return "AI auto-executes fixes"
        }
    }
}

// MARK: - Provider Configuration

struct ProviderConfig: Codable, Equatable {
    var apiKeys: [String: String] = [:]
    var models: [String: String] = [:]
    var endpoints: [String: String] = [:]

    /// Returns the API key for a provider: stored key → environment variable → empty
    func apiKey(for provider: AIProviderType) -> String {
        let stored = apiKeys[provider.rawValue] ?? ""
        if !stored.isEmpty { return stored }
        // Fallback to environment variable
        if let envName = provider.envKeyName,
           let envValue = ProcessInfo.processInfo.environment[envName],
           !envValue.isEmpty {
            return envValue
        }
        return ""
    }

    /// Returns true if the key came from an environment variable (not stored)
    func isKeyFromEnv(for provider: AIProviderType) -> Bool {
        let stored = apiKeys[provider.rawValue] ?? ""
        if !stored.isEmpty { return false }
        if let envName = provider.envKeyName,
           let envValue = ProcessInfo.processInfo.environment[envName],
           !envValue.isEmpty {
            return true
        }
        return false
    }

    mutating func setAPIKey(_ key: String, for provider: AIProviderType) {
        apiKeys[provider.rawValue] = key.isEmpty ? nil : key
    }

    func model(for provider: AIProviderType) -> String {
        let stored = models[provider.rawValue] ?? ""
        return stored.isEmpty ? provider.defaultModel : stored
    }

    mutating func setModel(_ model: String, for provider: AIProviderType) {
        models[provider.rawValue] = model.isEmpty ? nil : model
    }

    func endpoint(for provider: AIProviderType) -> String {
        let stored = endpoints[provider.rawValue] ?? ""
        return stored.isEmpty ? provider.defaultEndpoint : stored
    }

    mutating func setEndpoint(_ endpoint: String, for provider: AIProviderType) {
        endpoints[provider.rawValue] = endpoint.isEmpty ? nil : endpoint
    }

    /// Number of providers that have an API key configured (stored or from env)
    var configuredCount: Int {
        AIProviderType.allCases.filter { p in
            p != .auto && (!p.requiresAPIKey || !apiKey(for: p).isEmpty)
        }.count
    }
}
