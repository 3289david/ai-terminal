import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var testStatus: [AIProviderType: TestResult] = [:]
    @State private var testingProviders: Set<AIProviderType> = []

    enum TestResult {
        case success(String)
        case failure(String)
    }

    var body: some View {
        TabView {
            aiProvidersTab
                .tabItem { Label("AI Providers", systemImage: Icons.brain) }

            generalTab
                .tabItem { Label("General", systemImage: Icons.settings) }

            safetyTab
                .tabItem { Label("Safety", systemImage: Icons.shield) }
        }
        .frame(width: 620, height: 540)
        .onDisappear { appState.saveSettings() }
    }

    // MARK: - AI Providers

    private var aiProvidersTab: some View {
        @Bindable var state = appState

        return ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header with count
                HStack {
                    Text("23 AI Providers")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    let configured = state.providerConfig.configuredCount
                    Text("\(configured) configured")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.accentGreen)
                }

                // Quick status bar
                HStack(spacing: 12) {
                    statusPill(
                        count: AIProviderType.allCases.filter { !$0.requiresAPIKey && $0 != .auto }.count,
                        label: "Ready",
                        color: Theme.accentGreen
                    )
                    statusPill(
                        count: AIProviderType.allCases.filter { $0.requiresAPIKey && !state.providerConfig.apiKey(for: $0).isEmpty }.count,
                        label: "Keys Set",
                        color: Theme.accent
                    )
                    statusPill(
                        count: AIProviderType.allCases.filter { $0.requiresAPIKey && state.providerConfig.isKeyFromEnv(for: $0) }.count,
                        label: "From Env",
                        color: Theme.accentCyan
                    )
                    statusPill(
                        count: AIProviderType.allCases.filter { $0.requiresAPIKey && state.providerConfig.apiKey(for: $0).isEmpty }.count,
                        label: "No Key",
                        color: Theme.textMuted
                    )
                    Spacer()
                }
                .padding(.bottom, 4)

                // Env var hint
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.accent)
                    Text("API keys auto-detected from environment variables (e.g. OPENAI_API_KEY)")
                        .font(.system(size: 11))
                        .foregroundColor(Theme.textMuted)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Theme.accent.opacity(0.06))
                .cornerRadius(6)

                ForEach(ProviderCategory.allCases, id: \.self) { category in
                    let providers = AIProviderType.allCases.filter {
                        $0 != .auto && $0.category == category
                    }
                    if !providers.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text(category.rawValue)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Theme.textPrimary)
                                Text("\(providers.count)")
                                    .font(Theme.captionFont)
                                    .foregroundColor(Theme.textMuted)
                                    .padding(.horizontal, 5)
                                    .padding(.vertical, 1)
                                    .background(Theme.inputBackground)
                                    .cornerRadius(3)
                            }
                            .padding(.horizontal, 4)

                            ForEach(providers) { provider in
                                ProviderConfigRow(
                                    provider: provider,
                                    config: $state.providerConfig,
                                    testStatus: testStatus[provider],
                                    isTesting: testingProviders.contains(provider),
                                    onTest: { testProvider(provider) }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private func statusPill(count: Int, label: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 6, height: 6)
            Text("\(count)").font(.system(size: 11, weight: .bold)).foregroundColor(color)
            Text(label).font(.system(size: 10)).foregroundColor(Theme.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.08))
        .cornerRadius(4)
    }

    private func testProvider(_ provider: AIProviderType) {
        testingProviders.insert(provider)
        testStatus[provider] = nil

        Task {
            let config = appState.providerConfig

            do {
                let router = AIRouter()
                router.configure(with: config)
                let (response, _) = try await router.complete(
                    prompt: "Say 'OK' in one word.",
                    systemPrompt: "Reply with exactly one word: OK",
                    provider: provider
                )
                let trimmed = response.trimmingCharacters(in: .whitespacesAndNewlines)
                await MainActor.run {
                    testStatus[provider] = .success("Connected — \(trimmed.prefix(30))")
                    testingProviders.remove(provider)
                }
            } catch {
                await MainActor.run {
                    testStatus[provider] = .failure(error.localizedDescription)
                    testingProviders.remove(provider)
                }
            }
        }
    }

    // MARK: - General

    private var generalTab: some View {
        @Bindable var state = appState

        return Form {
            Section("Default AI Provider") {
                Picker("Provider", selection: $state.selectedProvider) {
                    ForEach(AIProviderType.allCases) { p in
                        Label(p.rawValue, systemImage: p.icon).tag(p)
                    }
                }
            }

            Section("Execution Mode") {
                Picker("Mode", selection: $state.executionMode) {
                    ForEach(ExecutionMode.allCases) { mode in
                        VStack(alignment: .leading) {
                            Label(mode.rawValue, systemImage: mode.icon)
                            Text(mode.subtitle)
                                .font(Theme.captionFont)
                                .foregroundColor(Theme.textMuted)
                        }
                        .tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)
            }

            Section("Terminal") {
                Toggle("Auto-detect errors", isOn: .constant(true))
                Toggle("Show AI panel on launch", isOn: $state.showAIPanel)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    // MARK: - Safety

    private var safetyTab: some View {
        Form {
            Section("Safety Features") {
                Toggle("Block dangerous commands", isOn: .constant(true))
                Toggle("API key leak detection", isOn: .constant(true))
                Toggle("Confirm before auto-execute", isOn: .constant(true))
            }

            Section("Detected Patterns") {
                Text("These patterns are automatically flagged:")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)

                VStack(alignment: .leading, spacing: 4) {
                    riskRow("rm -rf /", .dangerous)
                    riskRow("Fork bombs", .dangerous)
                    riskRow("mkfs / dd commands", .dangerous)
                    riskRow("sudo commands", .caution)
                    riskRow("git push --force", .caution)
                    riskRow("DROP TABLE / DATABASE", .caution)
                    riskRow("curl | sh piping", .caution)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func riskRow(_ text: String, _ level: RiskLevel) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(level == .dangerous ? Theme.accentRed : Theme.accentOrange)
                .frame(width: 6, height: 6)
            Text(text)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textPrimary)
        }
    }
}

// MARK: - Provider Config Row

struct ProviderConfigRow: View {
    let provider: AIProviderType
    @Binding var config: ProviderConfig
    var testStatus: SettingsView.TestResult?
    var isTesting: Bool
    var onTest: () -> Void
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 10) {
                // API Key field (for all providers that need one)
                if provider.requiresAPIKey {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("API Key")
                                .font(Theme.captionFont)
                                .frame(width: 65, alignment: .trailing)
                            SecureField(provider.envKeyName.map { "Enter key or set \($0)" } ?? "Enter API key", text: apiKeyBinding)
                                .textFieldStyle(.roundedBorder)
                        }

                        // Env var + Get Key row
                        HStack(spacing: 8) {
                            Spacer().frame(width: 65)

                            if config.isKeyFromEnv(for: provider), let envName = provider.envKeyName {
                                HStack(spacing: 3) {
                                    Image(systemName: "terminal")
                                        .font(.system(size: 8))
                                    Text("from \(envName)")
                                        .font(.system(size: 9))
                                }
                                .foregroundColor(Theme.accentCyan)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.accentCyan.opacity(0.1))
                                .cornerRadius(3)
                            }

                            if let url = provider.apiKeyURL {
                                Link(destination: URL(string: url)!) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "key.fill")
                                            .font(.system(size: 8))
                                        Text("Get API Key")
                                            .font(.system(size: 9, weight: .medium))
                                    }
                                    .foregroundColor(Theme.accent)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Theme.accent.opacity(0.1))
                                    .cornerRadius(3)
                                }
                            }

                            Spacer()
                        }
                    }
                }

                // Model field (for ALL providers)
                HStack {
                    Text("Model")
                        .font(Theme.captionFont)
                        .frame(width: 65, alignment: .trailing)
                    TextField(provider.defaultModel, text: modelBinding)
                        .textFieldStyle(.roundedBorder)
                }

                // Endpoint field (for ALL providers, not just local)
                HStack {
                    Text("Endpoint")
                        .font(Theme.captionFont)
                        .frame(width: 65, alignment: .trailing)
                    TextField(provider.defaultEndpoint, text: endpointBinding)
                        .textFieldStyle(.roundedBorder)
                }

                // Test connection + status
                HStack(spacing: 8) {
                    Spacer().frame(width: 65)

                    Button(action: onTest) {
                        HStack(spacing: 4) {
                            if isTesting {
                                ProgressView()
                                    .controlSize(.mini)
                            } else {
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 9))
                            }
                            Text(isTesting ? "Testing..." : "Test Connection")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isTesting ? Color.gray : Theme.accent)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                    .disabled(isTesting || (provider.requiresAPIKey && config.apiKey(for: provider).isEmpty))

                    if let status = testStatus {
                        switch status {
                        case .success(let msg):
                            HStack(spacing: 3) {
                                Image(systemName: Icons.checkmark)
                                    .font(.system(size: 9))
                                Text(msg)
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(Theme.accentGreen)
                        case .failure(let msg):
                            HStack(spacing: 3) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 9))
                                Text(msg.prefix(50))
                                    .font(.system(size: 9))
                                    .lineLimit(1)
                            }
                            .foregroundColor(Theme.accentRed)
                        }
                    }

                    Spacer()
                }
            }
            .padding(.leading, 28)
            .padding(.vertical, 6)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: provider.icon)
                    .foregroundColor(Theme.accent)
                    .frame(width: 20)
                Text(provider.rawValue)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                Text(provider.subtitle)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
                Spacer()

                // Status badges
                if !provider.requiresAPIKey {
                    Text("Ready")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accentGreen.opacity(0.15))
                        .cornerRadius(3)
                } else if !config.apiKey(for: provider).isEmpty {
                    HStack(spacing: 2) {
                        Image(systemName: Icons.checkmark)
                            .font(.system(size: 8))
                        if config.isKeyFromEnv(for: provider) {
                            Text("env")
                                .font(.system(size: 8))
                        }
                    }
                    .foregroundColor(Theme.accentGreen)
                } else {
                    Text("No key")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.textMuted.opacity(0.1))
                        .cornerRadius(3)
                }
            }
        }
        .padding(Theme.paddingSmall)
        .background(Theme.cardBackground)
        .cornerRadius(Theme.cornerRadiusSmall)
    }

    private var apiKeyBinding: Binding<String> {
        Binding(
            get: { config.apiKey(for: provider) },
            set: { config.setAPIKey($0, for: provider) }
        )
    }

    private var modelBinding: Binding<String> {
        Binding(
            get: { config.models[provider.rawValue] ?? "" },
            set: { config.setModel($0, for: provider) }
        )
    }

    private var endpointBinding: Binding<String> {
        Binding(
            get: { config.endpoints[provider.rawValue] ?? "" },
            set: { config.setEndpoint($0, for: provider) }
        )
    }
}
