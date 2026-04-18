import SwiftUI

struct ProviderSelector: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            Button(action: { appState.selectedProvider = .auto }) {
                HStack {
                    Label("Auto - Best available", systemImage: AIProviderType.auto.icon)
                    if appState.selectedProvider == .auto {
                        Image(systemName: Icons.checkmark)
                    }
                }
            }

            Divider()

            ForEach(ProviderCategory.allCases, id: \.self) { category in
                let providers = AIProviderType.allCases.filter {
                    $0 != .auto && $0.category == category
                }
                if !providers.isEmpty {
                    Menu(category.rawValue) {
                        ForEach(providers) { provider in
                            providerButton(provider)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: appState.selectedProvider.icon)
                Text(appState.selectedProvider.rawValue)
                    .font(Theme.captionFont)
                Image(systemName: Icons.chevronDown)
                    .font(.system(size: 8))
            }
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Select AI Provider (\(AIProviderType.allCases.count - 1) available)")
    }

    private func providerButton(_ provider: AIProviderType) -> some View {
        Button(action: {
            appState.selectedProvider = provider
            appState.saveSettings()
        }) {
            HStack {
                Label {
                    VStack(alignment: .leading) {
                        Text(provider.rawValue)
                        Text(provider.subtitle)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                } icon: {
                    Image(systemName: provider.icon)
                }
                Spacer()
                if provider == appState.selectedProvider {
                    Image(systemName: Icons.checkmark)
                }
            }
        }
    }
}
