import SwiftUI

@Observable
final class TerminalViewModel {
    // Services
    private let ptyService = PTYService()
    let aiRouter = AIRouter()
    let memoryStore = MemoryStore()

    // Terminal state
    var rawOutput: String = ""
    var parsedSegments: [ANSISegment] = []
    var commandHistory: [String] = []
    var historyIndex: Int = -1
    var isRunning: Bool = false
    var currentDirectory: String = ""

    // AI state
    var aiResponse: String = ""
    var aiProvider: AIProviderType = .auto
    var isAIStreaming: Bool = false
    var suggestions: [CommandSuggestion] = []
    var showAIPanel: Bool = false
    var aiMessages: [AIMessage] = []

    // Input
    var inputText: String = ""
    var aiQuestion: String = ""

    // Scroll control -- use a counter instead of Bool to avoid onChange multi-fire
    var scrollGeneration: Int = 0

    // Error detection buffer
    private var lastCommand: String = ""
    private var errorBuffer: String = ""
    private var outputAccumulator: String = ""
    private var parseTimer: Timer?

    // Auto-error detection
    var detectedError: Bool = false

    // MARK: - Lifecycle

    func start(config: ProviderConfig, directory: String) {
        currentDirectory = directory
        aiRouter.configure(with: config)

        // Refresh availability with graceful timeout so Ollama "Connection refused" is silent
        Task {
            await aiRouter.refreshAvailability()
        }

        ptyService.start(
            workingDirectory: directory,
            onOutput: { [weak self] data in self?.handleOutput(data) },
            onExit:   { [weak self] in
                self?.isRunning = false
                self?.detectedError = false
            }
        )
        isRunning = true
    }

    /// Reconfigure the AI router with updated provider config (e.g. after Settings changes)
    func reconfigure(with config: ProviderConfig) {
        aiRouter.configure(with: config)
        Task {
            await aiRouter.refreshAvailability()
        }
    }

    func stop() {
        parseTimer?.invalidate()
        parseTimer = nil
        ptyService.stop()
        isRunning = false
    }

    // MARK: - Terminal Input

    func sendCommand(_ command: String) {
        guard !command.isEmpty else { return }
        lastCommand = command
        errorBuffer = ""
        detectedError = false

        let trimmed = command.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty {
            commandHistory.append(trimmed)
            historyIndex = commandHistory.count
        }

        ptyService.write(command + "\n")
        inputText = ""
    }

    func sendRawInput(_ text: String) {
        ptyService.write(text)
    }

    func sendInterrupt() { ptyService.sendInterrupt() }
    func sendEOF()       { ptyService.sendEOF() }
    func sendTab()       { ptyService.write("\t") }

    func navigateHistory(up: Bool) {
        guard !commandHistory.isEmpty else { return }
        if up {
            historyIndex = max(0, historyIndex - 1)
        } else {
            historyIndex = min(commandHistory.count, historyIndex + 1)
        }
        inputText = historyIndex < commandHistory.count
            ? commandHistory[historyIndex]
            : ""
    }

    func resize(rows: UInt16, cols: UInt16) {
        ptyService.resize(rows: rows, cols: cols)
    }

    func clearTerminal() {
        rawOutput = ""
        parsedSegments = []
        outputAccumulator = ""
        errorBuffer = ""
        detectedError = false
    }

    // MARK: - AI: Ask

    func askAI(question: String, provider: AIProviderType) {
        guard !question.isEmpty else { return }
        aiMessages.append(AIMessage(role: .user, content: question))
        beginAI()

        Task { @MainActor in
            let ctx = await buildContext(isError: false)
            let sys = AIPromptBuilder.systemPrompt(context: ctx)
            let (stream, resolved) = aiRouter.stream(
                prompt: question, systemPrompt: sys, provider: provider
            )
            aiProvider = resolved

            do {
                for try await token in stream { aiResponse += token }
                extractSuggestions()
                aiMessages.append(AIMessage(role: .assistant, content: aiResponse, provider: resolved))
            } catch {
                let errMsg = "[Error: \(error.localizedDescription)]"
                aiResponse += "\n\n\(errMsg)"
                aiMessages.append(AIMessage(role: .error, content: errMsg))
            }
            isAIStreaming = false
        }
    }

    // MARK: - AI: Analyze Error

    func analyzeError(provider: AIProviderType) {
        beginAI()

        Task { @MainActor in
            let ctx = await buildContext(isError: true)

            // Check memory for similar past errors
            let memories = memoryStore.recall(error: ctx.output)
            var prompt = AIPromptBuilder.errorPrompt(context: ctx)
            if !memories.isEmpty {
                prompt += "\n\nPrevious similar issues:\n"
                for m in memories {
                    prompt += "- `\(m.command)` -> \(m.solution)\n"
                }
            }

            let sys = AIPromptBuilder.systemPrompt(context: ctx)
            let (stream, resolved) = aiRouter.stream(
                prompt: prompt, systemPrompt: sys, provider: provider
            )
            aiProvider = resolved

            do {
                for try await token in stream { aiResponse += token }
                extractSuggestions()

                // Remember this error + solution
                if !aiResponse.isEmpty {
                    memoryStore.remember(
                        command: lastCommand,
                        error: String(ctx.output.prefix(500)),
                        solution: String(aiResponse.prefix(500)),
                        directory: currentDirectory
                    )
                }

                aiMessages.append(AIMessage(role: .assistant, content: aiResponse, provider: resolved))
            } catch {
                aiResponse += "\n\n[Error: \(error.localizedDescription)]"
            }
            isAIStreaming = false
        }
    }

    // MARK: - AI: Explain Command

    func explainCommand(_ command: String, provider: AIProviderType) {
        aiMessages.append(AIMessage(role: .user, content: "Explain: \(command)"))
        beginAI()

        Task { @MainActor in
            let sys = """
            You are an expert terminal assistant. Explain commands clearly and concisely. \
            Break down each part. Mention any risks or side effects.
            """
            let prompt = AIPromptBuilder.explainPrompt(command: command)
            let (stream, resolved) = aiRouter.stream(
                prompt: prompt, systemPrompt: sys, provider: provider
            )
            aiProvider = resolved

            do {
                for try await token in stream { aiResponse += token }
                aiMessages.append(AIMessage(role: .assistant, content: aiResponse, provider: resolved))
            } catch {
                aiResponse += "\n\n[Error: \(error.localizedDescription)]"
            }
            isAIStreaming = false
        }
    }

    // MARK: - Run suggestion

    func runSuggestion(_ command: String) {
        let verdict = SafetyLayer.evaluate(command: command)
        switch verdict {
        case .dangerous(let reason):
            aiResponse += "\n\n[BLOCKED] \(reason). Command was not executed."
            return
        case .caution(let reason):
            aiResponse += "\n\n[WARNING] \(reason). Proceeding..."
            sendCommand(command)
        case .safe:
            sendCommand(command)
        }
    }

    // MARK: - Private helpers

    private func beginAI() {
        isAIStreaming = true
        aiResponse = ""
        suggestions = []
        showAIPanel = true
    }

    private func handleOutput(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        rawOutput += text
        outputAccumulator += text

        // Cap raw buffer at 100 KB
        if rawOutput.count > 100_000 {
            rawOutput = String(rawOutput.suffix(60_000))
        }

        // Debounce ANSI parsing to avoid onChange multi-fire
        parseTimer?.invalidate()
        parseTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            guard let self else { return }
            let toParse = self.outputAccumulator
            self.outputAccumulator = ""

            // Parse on background then update on main
            DispatchQueue.global(qos: .userInteractive).async {
                let newSegments = ANSIParser.parse(toParse)

                DispatchQueue.main.async {
                    self.parsedSegments.append(contentsOf: newSegments)

                    // Cap segments at ~5000
                    if self.parsedSegments.count > 5000 {
                        self.parsedSegments = Array(self.parsedSegments.suffix(3000))
                    }

                    // Single increment avoids multi-fire
                    self.scrollGeneration += 1
                }
            }
        }

        // Error detection
        let lower = text.lowercased()
        let errorKeywords = ["error:", "fatal:", "failed", "exception",
                             "permission denied", "not found", "eacces", "enoent",
                             "segmentation fault", "panic:", "traceback"]
        if errorKeywords.contains(where: { lower.contains($0) }) {
            errorBuffer += text
            detectedError = true
        }

        // Secret leak detection
        if SafetyLayer.detectSecretLeak(in: text) {
            aiResponse = "[WARNING] Potential API key or secret detected in terminal output."
            showAIPanel = true
        }
    }

    private func buildContext(isError: Bool) async -> AIContext {
        AIContext(
            command: lastCommand,
            output: isError
                ? (errorBuffer.isEmpty ? String(rawOutput.suffix(2000)) : errorBuffer)
                : String(rawOutput.suffix(2000)),
            isError: isError,
            currentDirectory: currentDirectory,
            projectInfo: await ContextEngine.describe(directory: currentDirectory),
            recentHistory: Array(commandHistory.suffix(10))
        )
    }

    private func extractSuggestions() {
        suggestions.removeAll()
        let pattern = "```(?:bash|sh|zsh)?\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return }
        let ns = NSRange(aiResponse.startIndex..., in: aiResponse)
        let matches = regex.matches(in: aiResponse, range: ns)

        for match in matches {
            guard let range = Range(match.range(at: 1), in: aiResponse) else { continue }
            let code = String(aiResponse[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            let cmds = code.components(separatedBy: .newlines)
                .filter { !$0.isEmpty && !$0.hasPrefix("#") }

            for cmd in cmds {
                let verdict = SafetyLayer.evaluate(command: cmd)
                let risk: RiskLevel
                switch verdict {
                case .safe:      risk = .safe
                case .caution:   risk = .caution
                case .dangerous: risk = .dangerous
                }
                suggestions.append(CommandSuggestion(command: cmd, explanation: "", risk: risk))
            }
        }
    }

    deinit {
        parseTimer?.invalidate()
        ptyService.stop()
    }
}
