import SwiftUI

struct AIResponsePanel: View {
    @Bindable var viewModel: TerminalViewModel
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider().background(Theme.border)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.paddingMedium) {
                        // Conversation history
                        ForEach(viewModel.aiMessages) { msg in
                            MessageBubble(message: msg)
                        }

                        // Live streaming response
                        if viewModel.isAIStreaming {
                            streamingBubble
                        } else if !viewModel.aiResponse.isEmpty && viewModel.aiMessages.isEmpty {
                            responseContent
                        }

                        // Suggestions
                        if !viewModel.suggestions.isEmpty { suggestionsSection }

                        // Empty state
                        if viewModel.aiResponse.isEmpty && !viewModel.isAIStreaming && viewModel.aiMessages.isEmpty {
                            emptyState
                        }

                        Color.clear.frame(height: 1).id("ai-bottom")
                    }
                    .padding(Theme.paddingMedium)
                }
                .background(Theme.panelBackground)
                .onChange(of: viewModel.aiResponse) { _, _ in
                    withAnimation(.easeOut(duration: 0.1)) {
                        proxy.scrollTo("ai-bottom", anchor: .bottom)
                    }
                }
            }
        }
        .background(Theme.panelBackground)
    }

    // MARK: - Header

    private var panelHeader: some View {
        HStack {
            Image(systemName: Icons.brain)
                .foregroundColor(Theme.accent)
            Text("AI Assistant")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)

            Spacer()

            // Provider availability summary
            HStack(spacing: 4) {
                let available = AIProviderType.allCases.filter {
                    $0 != .auto && viewModel.aiRouter.isAvailable($0)
                }.count
                Circle()
                    .fill(available > 0 ? Theme.accentGreen : Theme.textMuted)
                    .frame(width: 6, height: 6)
                Text("\(available) online")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textMuted)
            }

            // Show selected provider (and resolved provider if different, e.g. in Auto mode)
            let selected = appState.selectedProvider
            let resolved = viewModel.aiProvider
            if selected == .auto && resolved != .auto {
                // Auto mode: show which provider was actually used
                Label("\(selected.rawValue) → \(resolved.rawValue)", systemImage: resolved.icon)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent.opacity(0.1))
                    .cornerRadius(Theme.cornerRadiusSmall)
            } else if selected != .auto {
                Label(selected.rawValue, systemImage: selected.icon)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent.opacity(0.1))
                    .cornerRadius(Theme.cornerRadiusSmall)
            }

            Button(action: {
                viewModel.aiMessages.removeAll()
                viewModel.aiResponse = ""
                viewModel.suggestions = []
            }) {
                Image(systemName: Icons.trash)
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textMuted)
            }
            .buttonStyle(.plain)
            .help("Clear conversation")

            Button(action: { viewModel.showAIPanel = false }) {
                Image(systemName: Icons.xmark)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Theme.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 10)
        .background(Theme.cardBackground)
    }

    // MARK: - Streaming

    private var streamingBubble: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Thinking...")
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            if !viewModel.aiResponse.isEmpty {
                Text(viewModel.aiResponse)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .textSelection(.enabled)
                    .lineSpacing(4)
            }
        }
        .padding(Theme.paddingMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.terminalBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.accent.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Response (non-conversational fallback)

    private var responseContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.aiResponse)
                .font(Theme.bodyFont)
                .foregroundColor(Theme.textPrimary)
                .textSelection(.enabled)
                .lineSpacing(4)

            HStack {
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(viewModel.aiResponse, forType: .string)
                }) {
                    Label("Copy", systemImage: Icons.copy)
                        .font(Theme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Theme.textSecondary)
            }
        }
        .padding(Theme.paddingMedium)
        .background(Theme.terminalBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.border, lineWidth: 1)
        )
    }

    // MARK: - Suggestions

    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: Icons.wand)
                    .foregroundColor(Theme.accentPurple)
                    .font(.system(size: 12))
                Text("Suggested Commands")
                    .font(Theme.headingFont)
                    .foregroundColor(Theme.textPrimary)
            }

            ForEach(viewModel.suggestions) { suggestion in
                CommandCard(
                    suggestion: suggestion,
                    onRun: { viewModel.runSuggestion(suggestion.command) },
                    onCopy: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(suggestion.command, forType: .string)
                    },
                    onExplain: {
                        viewModel.explainCommand(suggestion.command, provider: appState.selectedProvider)
                    }
                )
            }
        }
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: Theme.paddingMedium) {
            Image(systemName: Icons.sparkle)
                .font(.system(size: 40))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.accent, Theme.accentPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("AI Assistant Ready")
                .font(Theme.headingFont)
                .foregroundColor(Theme.textPrimary)

            Text("Ask a question, analyze an error, or get command suggestions")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 8) {
                hintRow(Icons.fix,      "\"Fix this error\"",          Theme.accentRed)
                hintRow(Icons.explain,  "\"Explain this command\"",    Theme.accent)
                hintRow(Icons.generate, "\"Generate a Dockerfile\"",   Theme.accentPurple)
                hintRow(Icons.retry,    "\"Retry with fixes\"",        Theme.accentOrange)
                hintRow(Icons.shield,   "\"Is this command safe?\"",   Theme.accentGreen)
                hintRow(Icons.memory,   "\"What errors have I seen?\"",Theme.accentCyan)
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func hintRow(_ icon: String, _ text: String, _ color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)
            Text(text)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
        }
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: AIMessage

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                // Role label
                HStack(spacing: 4) {
                    if message.role != .user {
                        Image(systemName: message.role == .error ? Icons.error : Icons.robot)
                            .font(.system(size: 10))
                            .foregroundColor(message.role == .error ? Theme.accentRed : Theme.accent)
                    }
                    if let provider = message.provider {
                        Text(provider.rawValue)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Theme.textMuted)
                    }
                    Text(message.timestamp, style: .time)
                        .font(.system(size: 9))
                        .foregroundColor(Theme.textMuted)
                }

                // Content
                Text(message.content)
                    .font(Theme.bodyFont)
                    .foregroundColor(
                        message.role == .error ? Theme.accentRed : Theme.textPrimary
                    )
                    .textSelection(.enabled)
                    .lineSpacing(3)
                    .padding(Theme.paddingSmall + 2)
                    .background(bubbleBackground)
                    .cornerRadius(Theme.cornerRadius)
            }

            if message.role != .user {
                Spacer(minLength: 40)
            }
        }
    }

    private var bubbleBackground: Color {
        switch message.role {
        case .user:      return Theme.accent.opacity(0.15)
        case .assistant: return Theme.terminalBackground
        case .error:     return Theme.accentRed.opacity(0.1)
        case .system:    return Theme.cardBackground
        }
    }
}
