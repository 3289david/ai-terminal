import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @State private var testStatus: [AIProviderType: String] = [:]

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
                HStack {
                    Text("23 AI Providers")
                        .font(Theme.headingFont)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    let configured = AIProviderType.allCases.filter { p in
                        p != .auto && (!p.requiresAPIKey || !state.providerConfig.apiKey(for: p).isEmpty)
                    }.count
                    Text("\(configured) configured")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.accentGreen)
                }

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
                                    config: $state.providerConfig
                                )
                            }
                        }
                    }
                }
            }
            .padding()
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
    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            VStack(alignment: .leading, spacing: 8) {
                if provider.requiresAPIKey {
                    HStack {
                        Text("API Key")
                            .font(Theme.captionFont)
                            .frame(width: 65, alignment: .trailing)
                        SecureField("Enter API key", text: apiKeyBinding)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                HStack {
                    Text("Model")
                        .font(Theme.captionFont)
                        .frame(width: 65, alignment: .trailing)
                    TextField(provider.defaultModel, text: modelBinding)
                        .textFieldStyle(.roundedBorder)
                }
                if provider.isLocal {
                    HStack {
                        Text("Endpoint")
                            .font(Theme.captionFont)
                            .frame(width: 65, alignment: .trailing)
                        TextField(provider.defaultEndpoint, text: endpointBinding)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            .padding(.leading, 28)
            .padding(.vertical, 4)
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
                if !provider.requiresAPIKey {
                    Text("No key needed")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Theme.accentGreen)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Theme.accentGreen.opacity(0.15))
                        .cornerRadius(3)
                } else if !config.apiKey(for: provider).isEmpty {
                    Image(systemName: Icons.checkmark)
                        .foregroundColor(Theme.accentGreen)
                        .font(.system(size: 10))
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
