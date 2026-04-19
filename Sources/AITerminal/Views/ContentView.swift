import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @State private var viewModels: [UUID: TerminalViewModel] = [:]
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    private var activeVM: TerminalViewModel? {
        guard let id = appState.activeSessionID else { return nil }
        return viewModels[id]
    }

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
        } detail: {
            if let vm = activeVM {
                HSplitView {
                    TerminalView(viewModel: vm)
                        .frame(minWidth: 400)

                    if vm.showAIPanel {
                        AIResponsePanel(viewModel: vm)
                            .frame(minWidth: 300, idealWidth: 400, maxWidth: 600)
                    }
                }
            } else {
                Text("No active session")
                    .foregroundColor(Theme.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.terminalBackground)
            }
        }
        .background(Theme.windowBackground)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                ProviderSelector()

                if let vm = activeVM {
                    Button(action: { vm.showAIPanel.toggle() }) {
                        Image(systemName: vm.showAIPanel ? Icons.brain : Icons.brain)
                            .symbolVariant(vm.showAIPanel ? .fill : .none)
                    }
                    .help("Toggle AI Panel")
                }

                ExecutionModeButton()
            }
        }
        .onAppear {
            ensureVM(for: appState.activeSessionID)
        }
        .onChange(of: appState.activeSessionID) { _, newID in
            ensureVM(for: newID)
        }
        .onChange(of: appState.providerConfig) { _, newConfig in
            // Reconfigure all existing session routers when user changes API keys/settings
            for (_, vm) in viewModels {
                vm.reconfigure(with: newConfig)
            }
        }
        .onChange(of: appState.sessions.count) { oldCount, newCount in
            if newCount > oldCount, let id = appState.activeSessionID {
                ensureVM(for: id)
            }
            // Clean up VMs for removed sessions
            let sessionIDs = Set(appState.sessions.map(\.id))
            for key in viewModels.keys where !sessionIDs.contains(key) {
                viewModels[key]?.stop()
                viewModels.removeValue(forKey: key)
            }
        }
    }

    private func ensureVM(for id: UUID?) {
        guard let id else { return }
        if viewModels[id] == nil {
            let vm = TerminalViewModel()
            let dir = appState.sessions.first(where: { $0.id == id })?.currentDirectory
                ?? FileManager.default.homeDirectoryForCurrentUser.path
            vm.start(config: appState.providerConfig, directory: dir)
            viewModels[id] = vm
        }
    }
}

// MARK: - Execution Mode Button

struct ExecutionModeButton: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Menu {
            ForEach(ExecutionMode.allCases) { mode in
                Button(action: {
                    appState.executionMode = mode
                    appState.saveSettings()
                }) {
                    Label {
                        VStack(alignment: .leading) {
                            Text(mode.rawValue)
                            Text(mode.subtitle)
                                .font(.caption2)
                        }
                    } icon: {
                        Image(systemName: mode.icon)
                    }
                }
            }
        } label: {
            Label(appState.executionMode.rawValue, systemImage: appState.executionMode.icon)
        }
        .help("Execution Mode: \(appState.executionMode.subtitle)")
    }
}
