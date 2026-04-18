import SwiftUI

struct SidebarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var state = appState

        VStack(spacing: 0) {
            // App branding
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Theme.accent, Theme.accentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 28, height: 28)
                    Image(systemName: Icons.terminal)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("AI Terminal")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                    Text("v2.0")
                        .font(.system(size: 10))
                        .foregroundColor(Theme.textMuted)
                }
                Spacer()
            }
            .padding(Theme.paddingMedium)

            Divider().background(Theme.border)

            // Sessions list
            List(selection: $state.activeSessionID) {
                Section("Sessions") {
                    ForEach(appState.sessions) { session in
                        sessionRow(session)
                            .tag(session.id)
                    }
                }
            }
            .listStyle(.sidebar)

            Divider().background(Theme.border)

            // Quick actions
            VStack(spacing: 4) {
                Button(action: { appState.createSession() }) {
                    HStack {
                        Image(systemName: Icons.plus)
                        Text("New Session")
                        Spacer()
                        Text("T")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Theme.textMuted)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Theme.inputBackground)
                            .cornerRadius(3)
                    }
                    .font(Theme.captionFont)
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, Theme.paddingMedium)
            .padding(.vertical, 8)

            Divider().background(Theme.border)

            // Status bar
            statusBar
        }
        .background(Theme.sidebarBackground)
    }

    // MARK: - Session Row

    private func sessionRow(_ session: TerminalSession) -> some View {
        HStack {
            Image(systemName: Icons.terminal)
                .foregroundColor(
                    session.id == appState.activeSessionID ? Theme.accentGreen : Theme.textMuted
                )
                .font(.system(size: 11))

            VStack(alignment: .leading, spacing: 2) {
                Text(session.name)
                    .font(Theme.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text(shortDir(session.currentDirectory))
                    .font(Theme.captionFont)
                    .foregroundColor(Theme.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            if appState.sessions.count > 1 {
                Button(action: { appState.closeSession(session.id) }) {
                    Image(systemName: Icons.xmark)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Theme.textMuted)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - Status

    private var statusBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Theme.accentGreen)
                .frame(width: 6, height: 6)
            Text("Ready")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)

            Spacer()

            Text("\(appState.sessions.count) session\(appState.sessions.count == 1 ? "" : "s")")
                .font(Theme.captionFont)
                .foregroundColor(Theme.textMuted)
        }
        .padding(.horizontal, Theme.paddingMedium)
        .padding(.vertical, 8)
    }

    private func shortDir(_ dir: String) -> String {
        dir.replacingOccurrences(
            of: FileManager.default.homeDirectoryForCurrentUser.path,
            with: "~"
        )
    }
}
