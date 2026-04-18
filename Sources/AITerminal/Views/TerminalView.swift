import SwiftUI

struct TerminalView: View {
    @Bindable var viewModel: TerminalViewModel
    @Environment(AppState.self) private var appState
    @State private var focusTrigger: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            terminalHeader
            Divider().background(Theme.border)
            terminalOutput
            Divider().background(Theme.border)
            inputArea
            Divider().background(Theme.border)
            aiQuickBar
        }
        .background(Theme.terminalBackground)
    }

    // MARK: - Header

    private var terminalHeader: some View {
        HStack(spacing: Theme.paddingSmall) {
            HStack(spacing: 8) {
                Circle().fill(Color.red.opacity(0.8)).frame(width: 12, height: 12)
                Circle().fill(Color.orange.opacity(0.8)).frame(width: 12, height: 12)
                Circle().fill(Color.green.opacity(0.8)).frame(width: 12, height: 12)
            }

            Spacer()

            Image(systemName: Icons.folder)
                .foregroundColor(Theme.textSecondary)
                .font(.system(size: 11))
            Text(shortDirectory)
                .font(Theme.captionFont)
                .foregroundColor(Theme.textSecondary)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 6) {
                if viewModel.detectedError {
                    Image(systemName: Icons.error)
                        .foregroundColor(Theme.accentRed)
                        .font(.system(size: 11))
                    Text("Error Detected")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.accentRed)
                }

                if viewModel.isRunning {
                    Circle().fill(Theme.accentGreen).frame(width: 8, height: 8)
                    Text("Running")
                        .font(Theme.captionFont)
                        .foregroundColor(Theme.textSecondary)
                }
            }

            Button(action: { viewModel.clearTerminal() }) {
                Image(systemName: Icons.trash)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textMuted)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .help("Clear terminal")
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, Theme.paddingSmall)
        .background(Theme.panelBackground)
    }

    // MARK: - Output with ANSI colors

    private var terminalOutput: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if viewModel.parsedSegments.isEmpty {
                        welcomeBanner
                    } else {
                        ANSITextView(segments: viewModel.parsedSegments)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Color.clear.frame(height: 1).id("bottom")
                }
                .padding(Theme.paddingMedium)
            }
            .background(Theme.terminalBackground)
            .contentShape(Rectangle())
            .simultaneousGesture(TapGesture().onEnded { focusTrigger += 1 })
            .onChange(of: viewModel.scrollGeneration) { _, _ in
                withAnimation(.easeOut(duration: 0.08)) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Welcome Banner

    private var welcomeBanner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("AI Terminal Assistant v2.0")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(Theme.accent)
            Text("Type a command below, or ask the AI for help.")
                .font(Theme.terminalFont)
                .foregroundColor(Theme.textSecondary)
            Text("")
            HStack(spacing: 0) {
                Text("Provider: ")
                    .font(Theme.terminalFontSmall)
                    .foregroundColor(Theme.textMuted)
                Text(appState.selectedProvider.rawValue)
                    .font(Theme.terminalFontSmall)
                    .foregroundColor(Theme.accentCyan)
                Text("  |  Mode: ")
                    .font(Theme.terminalFontSmall)
                    .foregroundColor(Theme.textMuted)
                Text(appState.executionMode.rawValue)
                    .font(Theme.terminalFontSmall)
                    .foregroundColor(Theme.accentGreen)
            }
            Text("")
        }
    }

    // MARK: - Command Input

    private var inputArea: some View {
        HStack(spacing: 8) {
            Text(viewModel.detectedError ? "!" : "$")
                .font(Theme.terminalFont)
                .foregroundColor(viewModel.detectedError ? Theme.accentRed : Theme.accentGreen)
                .frame(width: 14)

            AppTextField(
                text: $viewModel.inputText,
                placeholder: "Enter command...",
                font: .monospacedSystemFont(ofSize: 13, weight: .regular),
                onSubmit: {
                    let cmd = viewModel.inputText
                    viewModel.sendCommand(cmd)
                    // Force clear: sendCommand sets inputText = "" but NSTextField
                    // may not pick it up if isEditing is true.
                    viewModel.inputText = ""
                },
                onUpArrow: { viewModel.navigateHistory(up: true) },
                onDownArrow: { viewModel.navigateHistory(up: false) },
                onTab: { viewModel.sendTab() },
                onEscape: { viewModel.inputText = "" },
                autoFocus: true,
                focusTrigger: focusTrigger
            )

            HStack(spacing: 4) {
                Button(action: {
                    viewModel.sendInterrupt()
                    focusTrigger += 1
                }) {
                    Text("^C")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.inputBackground)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Send interrupt (Ctrl+C)")

                Button(action: {
                    viewModel.sendEOF()
                    focusTrigger += 1
                }) {
                    Text("^D")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textMuted)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Theme.inputBackground)
                        .cornerRadius(3)
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("Send EOF (Ctrl+D)")
            }
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 10)
        .background(Theme.panelBackground)
    }

    // MARK: - AI Quick Bar

    private var aiQuickBar: some View {
        HStack(spacing: Theme.paddingSmall) {
            Image(systemName: Icons.sparkle)
                .foregroundColor(Theme.accent)
                .font(.system(size: 12))

            AppTextField(
                text: $viewModel.aiQuestion,
                placeholder: "Ask AI anything...",
                font: .systemFont(ofSize: 13),
                onSubmit: {
                    let q = viewModel.aiQuestion
                    guard !q.isEmpty else { return }
                    viewModel.aiQuestion = ""
                    viewModel.askAI(question: q, provider: appState.selectedProvider)
                }
            )

            if viewModel.detectedError {
                Button(action: {
                    viewModel.analyzeError(provider: appState.selectedProvider)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: Icons.fix)
                        Text("Fix Error")
                    }
                    .font(Theme.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accentRed)
                .controlSize(.small)
                .focusable(false)
            } else {
                Button(action: {
                    viewModel.analyzeError(provider: appState.selectedProvider)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: Icons.fix)
                        Text("Analyze")
                    }
                    .font(Theme.captionFont)
                }
                .buttonStyle(.bordered)
                .tint(Theme.accentRed)
                .controlSize(.small)
                .focusable(false)
            }

            Button(action: {
                if let last = viewModel.commandHistory.last {
                    viewModel.explainCommand(last, provider: appState.selectedProvider)
                }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: Icons.explain)
                    Text("Explain")
                }
                .font(Theme.captionFont)
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
            .controlSize(.small)
            .focusable(false)

            Button(action: {
                guard !viewModel.aiQuestion.isEmpty else { return }
                viewModel.askAI(question: viewModel.aiQuestion, provider: appState.selectedProvider)
                viewModel.aiQuestion = ""
            }) {
                Image(systemName: Icons.paperplane)
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
            .controlSize(.small)
            .focusable(false)
            .disabled(viewModel.aiQuestion.isEmpty)

            // Provider indicator
            ProviderBadge(provider: appState.selectedProvider)
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 8)
        .background(Theme.cardBackground)
    }

    // MARK: - Helpers

    private var shortDirectory: String {
        viewModel.currentDirectory.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}

// MARK: - Provider Badge

struct ProviderBadge: View {
    let provider: AIProviderType

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: provider.icon)
                .font(.system(size: 9))
            Text(provider.rawValue)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundColor(Theme.textMuted)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(Theme.inputBackground)
        .cornerRadius(4)
    }
}
