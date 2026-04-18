import SwiftUI

struct CommandCard: View {
    let suggestion: CommandSuggestion
    let onRun: () -> Void
    let onCopy: () -> Void
    let onExplain: () -> Void

    @State private var isHovered = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Command line
            HStack {
                Image(systemName: suggestion.riskIcon)
                    .foregroundColor(riskColor)
                    .font(.system(size: 14))

                Text(suggestion.command)
                    .font(Theme.codeFont)
                    .foregroundColor(Theme.textPrimary)
                    .textSelection(.enabled)

                Spacer()
            }

            if !suggestion.explanation.isEmpty {
                Text(suggestion.explanation)
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textSecondary)
            }

            // Action buttons
            HStack(spacing: 8) {
                Spacer()

                Button(action: onExplain) {
                    Label("Explain", systemImage: Icons.explain)
                        .font(Theme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Theme.textSecondary)

                Button(action: onCopy) {
                    Label("Copy", systemImage: Icons.copy)
                        .font(Theme.captionFont)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .tint(Theme.textSecondary)

                Button(action: onRun) {
                    Label("Run", systemImage: Icons.play)
                        .font(Theme.captionFont)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .tint(riskColor)
            }
        }
        .padding(Theme.paddingMedium)
        .background(isHovered ? Theme.inputBackground : Theme.terminalBackground)
        .cornerRadius(Theme.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(borderColor, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
    }

    private var riskColor: Color {
        switch suggestion.risk {
        case .safe:      return Theme.accentGreen
        case .caution:   return Theme.accentOrange
        case .dangerous: return Theme.accentRed
        }
    }

    private var borderColor: Color {
        switch suggestion.risk {
        case .safe:      return Theme.border
        case .caution:   return Theme.accentOrange.opacity(0.3)
        case .dangerous: return Theme.accentRed.opacity(0.3)
        }
    }
}
