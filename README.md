<div align="center">

<img src="https://img.shields.io/badge/Swift-5.9+-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+">
<img src="https://img.shields.io/badge/macOS-14.0+-000000?style=flat-square&logo=apple&logoColor=white" alt="macOS 14+">
<img src="https://img.shields.io/badge/Providers-23-blue?style=flat-square" alt="23 Providers">
<img src="https://img.shields.io/badge/.app-Bundle-8B5CF6?style=flat-square" alt=".app Bundle">
<img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="MIT License">
<img src="https://img.shields.io/badge/PRs-Welcome-brightgreen?style=flat-square" alt="PRs Welcome">

<br><br>

# ⚡ AI Terminal

### A real macOS app with an AI brain.

Not a CLI wrapper. Not an Electron shell. A **native `.app`** you drag to Applications.  
Built with SwiftUI + real PTY. 23 AI providers. Errors get analyzed. Commands get explained.

**[Features](#-features)** · **[Providers](#-supported-providers-23)** · **[Install](#-installation)** · **[CLI](#-cli-version-ait)** · **[Config](#%EF%B8%8F-configuration)** · **[Architecture](#-architecture)** · **[Contributing](#-contributing)**

---

<br>

```
╔══════════════════════════════════════════════════════════════════════╗
║                                                                      ║
║   ┌─────────────────────────────────────────────────────────────┐   ║
║   │  AI Terminal.app                                    ● ● ●  │   ║
║   ├─────────────────────────────────────────────────────────────┤   ║
║   │                                                             │   ║
║   │  $ npm run build                                            │   ║
║   │                                                             │   ║
║   │  ERROR in src/index.ts(42,5)                                │   ║
║   │  TS2345: Argument of type 'string' is not assignable        │   ║
║   │  to parameter of type 'number'.                             │   ║
║   │                                                             │   ║
║   │  ── AI detected error. Analyzing with Groq (0.3s) ──       │   ║
║   │                                                             │   ║
║   │  ✦ Type mismatch on line 42.                                │   ║
║   │                                                             │   ║
║   │  sed -i '' 's/userId/Number(userId)/' src/index.ts          │   ║
║   │                                                ✓ Safe       │   ║
║   │                                                             │   ║
║   │  [▶ Run]  [📋 Copy]  [💡 Explain]                           │   ║
║   └─────────────────────────────────────────────────────────────┘   ║
║                                                                      ║
╚══════════════════════════════════════════════════════════════════════╝
```

</div>

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 📦 **Native `.app` Bundle** | Real macOS application — shows in Dock, Launchpad, Spotlight. Just drag to `/Applications`. |
| 🖥️ **Real PTY Terminal** | Full `zsh --login` with ANSI 256-color, tab completion, history. Native `forkpty()` — not a web view. |
| 🤖 **23 AI Providers** | Ollama, OpenAI, Anthropic, Gemini, Groq, DeepSeek, Mistral, and 16 more. Auto mode picks the best available. |
| 🔍 **Auto Error Detection** | Detects errors in terminal output and offers one-click AI analysis with fix commands. |
| ⚡ **Token Streaming** | AI responses stream in real-time, token-by-token. Groq and Cerebras deliver under 1 second. |
| 💡 **Command Suggestions** | AI extracts runnable commands from responses with safety ratings (✓ Safe / ⚠ Caution / ✕ Blocked). |
| 🛡️ **Safety Layer** | Blocks `rm -rf /`, fork bombs, `dd` on disks. Warns on `sudo`, `git push --force`, `DROP TABLE`. |
| 🔐 **Secret Leak Detection** | Warns if API keys, GitHub tokens, or Slack tokens appear in commands or output. |
| 📑 **Multi-Session** | Multiple terminal tabs, each with its own PTY process and AI conversation context. |
| 🧠 **Memory Store** | Remembers past errors and solutions. Feeds them back to AI for smarter, project-aware answers. |
| 📂 **Context Engine** | Auto-detects project type (Node, Python, Rust, Go, Swift, etc.), git branch, and dependencies. |
| 🎛️ **Execution Modes** | Safe (recommend only), Assisted (suggest + run buttons), Autopilot (auto-execute suggestions). |
| 🌙 **Dark Theme** | GitHub Dark-inspired color palette with full ANSI 256-color and RGB support. |

### CLI-Only Features

| Feature | Description |
|---------|-------------|
| 📊 **Pipe Analysis** | `cmd 2>&1 \| ait --analyze` — pipe any command's output for instant AI analysis. |
| 💬 **Interactive REPL** | `ait -i` — full interactive mode with `/slash` commands, `!shell` execution, conversation history. |
| 🏃 **Run + Analyze** | `ait --run "npm test"` — runs a command and auto-analyzes errors with AI. |
| 📖 **Command Explain** | `ait --explain "find . -name '*.log' -delete"` — get detailed breakdowns of any command. |

---

## 🤖 Supported Providers (23)

<table>
<tr><th>Category</th><th>Providers</th><th>Notes</th></tr>
<tr><td>🏠 <b>Local</b></td><td>Ollama, LM Studio</td><td>Free, offline, private. No API key needed.</td></tr>
<tr><td>🆓 <b>Free</b></td><td>Pollinations</td><td>No API key. Works out of the box.</td></tr>
<tr><td>☁️ <b>Cloud</b></td><td>OpenAI, Anthropic, Google Gemini, Mistral, Cohere, xAI, DeepSeek, AI21</td><td>Premium models. Requires API keys.</td></tr>
<tr><td>⚡ <b>Fast Inference</b></td><td>Groq, Cerebras, SambaNova, Fireworks, Together, Lepton</td><td>Sub-second responses. Free tiers available.</td></tr>
<tr><td>🔀 <b>Aggregators</b></td><td>OpenRouter, DeepInfra, Perplexity, HuggingFace, Replicate</td><td>One key → hundreds of models.</td></tr>
</table>

**Auto mode** resolves the best available provider: local → fast free-tier → cloud → aggregator → Pollinations fallback.

---

## 📦 Installation

### Download the DMG (easiest)

```bash
git clone https://github.com/danwoo1234/ai-terminal.git
cd ai-terminal
make dmg
```

This builds `AI Terminal-2.0.0.dmg` in `.build/`. Open it, drag **AI Terminal.app** to Applications — done.

### Install the `.app` directly

```bash
make install
# Builds .app and copies to /Applications/AI Terminal.app
```

### Build the `.app` manually

```bash
make app                                       # Build .app to .build/
open ".build/AI Terminal.app"                  # Launch it
cp -R ".build/AI Terminal.app" /Applications/  # Or install manually
```

### Install the CLI (`ait`)

```bash
make install-cli
# installs `ait` to /usr/local/bin

# Or build and copy manually:
swift build -c release
cp .build/release/ait /usr/local/bin/
```

### Homebrew (coming soon)

```bash
brew tap danwoo1234/tap
brew install ai-terminal
```

### Makefile targets

| Target | Description |
|--------|-------------|
| `make dmg` | Build `AI Terminal-2.0.0.dmg` drag-to-install package |
| `make app` | Build `AI Terminal.app` in `.build/` |
| `make install` | Build `.app` and copy to `/Applications` |
| `make run` | Build `.app` and launch it |
| `make cli` | Build CLI binary (`ait`) |
| `make install-cli` | Build CLI and install to `/usr/local/bin` |
| `make clean` | Remove build artifacts |

### Requirements

- macOS 14.0 (Sonoma) or later
- Swift 5.9+ / Xcode 15+
- For local AI: [Ollama](https://ollama.ai) or [LM Studio](https://lmstudio.ai)

---

## 🖥️ CLI Version (`ait`)

A fully-featured headless CLI for use inside any existing terminal.

```
USAGE
  ait [OPTIONS] [QUERY...]
  command 2>&1 | ait --analyze
  ait -i
```

### Examples

```bash
# Ask anything
ait "how do I find large files on macOS?"

# Analyze an error (pipe stderr)
npm run build 2>&1 | ait --analyze

# Explain a command
ait --explain "find . -name '*.log' -mtime +30 -delete"

# Run a command with AI error analysis
ait --run "cargo build"

# Safety check
ait --safety "rm -rf node_modules"
# ⚠ Caution: Recursive force deletion

ait --safety "rm -rf /"
# ✕ BLOCKED: Recursive deletion from root

# Use a specific provider
ait --provider groq "optimize this SQL query"

# Interactive REPL
ait -i
```

### CLI Flags

| Flag | Description |
|------|-------------|
| `-i, --interactive` | Interactive REPL with slash commands and shell execution |
| `-a, --analyze` | Analyze piped input as an error |
| `-e, --explain CMD` | Explain a command in detail |
| `-r, --run CMD` | Run a command with AI error analysis |
| `-s, --safety CMD` | Check if a command is safe before running |
| `-p, --provider NAME` | Use a specific provider (default: auto) |
| `--list-providers` | List all 23 providers and their status |
| `--config` | Interactive configuration wizard |
| `--memory` | Show stored error/solution memories |
| `--version` | Show version |
| `-h, --help` | Show help |

### Interactive Mode Commands

| Command | Description |
|---------|-------------|
| `any text` | Ask the AI a question |
| `!command` | Run a shell command with AI error analysis |
| `/explain cmd` | Explain a command |
| `/run cmd` | Run with safety check + AI analysis |
| `/safety cmd` | Check command safety |
| `/providers` | List all AI providers |
| `/context` | Show detected project context |
| `/memory` | Show stored error memories |
| `/history` | Show command history |
| `/config` | Configure API keys |
| `/clear` | Clear screen |
| `exit` | Quit |

---

## ⌨️ Keyboard Shortcuts (GUI)

| Shortcut | Action |
|----------|--------|
| `⌘ T` | New session |
| `⌘ W` | Close session |
| `⌘ ,` | Settings |
| `↑ / ↓` | Navigate command history |
| `Tab` | Shell tab completion |
| `Esc` | Clear input |
| `^C` | Send interrupt (SIGINT) |
| `^D` | Send EOF |

---

## ⚙️ Configuration

### GUI

Open **Settings** (`⌘ ,`) to configure providers. Local providers and Pollinations work out of the box — just set API keys for cloud providers.

### CLI

```bash
# Interactive config wizard
ait --config

# Config files
~/.config/ai-terminal/config.json   # API keys, models, endpoints
~/.config/ai-terminal/memory.json   # Error/solution memory
~/.config/ai-terminal/history.txt   # Command history
```

The CLI and GUI app share configuration via UserDefaults, so configuring one works for both.

---

## 🛡️ Safety Layer

Every command is evaluated before execution:

| Level | Examples | Behavior |
|-------|----------|----------|
| ✕ **Blocked** | `rm -rf /`, `:(){ :\|:& };:`, `mkfs`, `dd if=... of=/dev/` | Prevented from running |
| ⚠ **Caution** | `sudo`, `git push --force`, `DROP TABLE`, `curl \| sh`, `chmod 777` | Warning shown, confirmation required |
| ✓ **Safe** | Everything else | Runs normally |

**Secret leak detection** scans commands, output, and AI responses for:
- API keys (`sk-...`, `api_key=...`)
- GitHub tokens (`ghp_...`)
- Slack tokens (`xoxb-...`)

---

## 🏗️ Architecture

```
.
├── Package.swift                  # SPM manifest
├── Makefile                       # Build targets (make app, make install)
├── Scripts/
│   ├── build-app.sh               # Assembles AI Terminal.app bundle
│   └── generate-icon.swift        # Generates app icon via CoreGraphics
├── Resources/
│   └── AITerminal.entitlements    # App sandbox entitlements
├── Sources/
│   ├── CPty/                      # C wrapper around forkpty()
│   │   ├── include/pty_wrapper.h
│   │   └── pty_wrapper.c
│   ├── AITerminal/                # SwiftUI macOS GUI app
│   │   ├── AITerminalApp.swift    # @main entry point
│   │   ├── Resources/Info.plist   # Bundle metadata
│   │   ├── Models/
│   │   │   ├── AIProvider.swift   # 23 provider definitions
│   │   │   ├── AppState.swift     # @Observable app state
│   │   │   └── Message.swift      # Message, CommandSuggestion types
│   │   ├── Services/
│   │   │   ├── AIRouter.swift     # Routes to correct AI client
│   │   │   ├── SafetyLayer.swift  # Command safety evaluation
│   │   │   ├── MemoryStore.swift  # Error/solution persistence
│   │   │   ├── ContextEngine.swift    # Project type detection
│   │   │   ├── PTYService.swift       # Pseudo-terminal management
│   │   │   ├── ANSIParser.swift       # Full ANSI escape parser
│   │   │   ├── OllamaClient.swift     # Ollama API client
│   │   │   ├── OpenAICompatibleClient.swift  # 15+ providers
│   │   │   ├── AnthropicClient.swift  # Claude API client
│   │   │   ├── GoogleGeminiClient.swift  # Gemini API client
│   │   │   └── PollinationsClient.swift  # Free fallback
│   │   ├── Views/
│   │   │   ├── ContentView.swift      # Main split view
│   │   │   ├── TerminalView.swift     # PTY terminal view
│   │   │   ├── AIResponsePanel.swift  # Streaming AI panel
│   │   │   ├── AppTextField.swift     # Custom NSTextField
│   │   │   ├── CommandCard.swift      # Runnable command cards
│   │   │   ├── SidebarView.swift      # Session sidebar
│   │   │   ├── SettingsView.swift     # Provider configuration
│   │   │   └── ProviderSelector.swift # Provider picker
│   │   └── Theme/                     # Colors, fonts
│   └── AITerminalCLI/                 # Headless CLI (brew/choco)
│       └── CLI.swift                  # Full CLI with all features
└── docs/
    └── index.html                     # GitHub Pages website
```

### The `.app` Bundle

Running `make app` produces a proper macOS application bundle:

```
AI Terminal.app/
└── Contents/
    ├── Info.plist                  # Bundle metadata + LSApplicationCategoryType
    ├── PkgInfo                    # APPL????
    ├── MacOS/
    │   └── AITerminal             # Compiled Mach-O executable
    └── Resources/
        └── AppIcon.icns           # Generated app icon (10 sizes)
```

The app shows in Dock, Launchpad, and Spotlight. No terminal needed to launch it.

### How It Works

1. **PTY Layer**: `forkpty()` spawns a real `zsh --login` process. Raw I/O is piped through `PTYService`.
2. **ANSI Parser**: Full SGR parser handles 256-color, RGB, bold/italic/underline, cursor movement.
3. **Error Detection**: 26 regex patterns scan terminal output for errors (exit codes, tracebacks, compiler errors).
4. **AI Router**: Routes queries through the correct client based on provider type (5 client kinds for 23 providers).
5. **Safety Layer**: Evaluates commands against dangerous/caution patterns before execution.
6. **Memory Store**: Persists error→solution pairs as JSON, recalls past fixes by keyword similarity scoring.
7. **Context Engine**: Detects project type from manifest files, reads git state, and injects context into AI prompts.

---

## 🔌 Adding a New Provider

It takes ~5 lines of code:

1. Add a case to `AIProviderType` in `Sources/AITerminal/Models/AIProvider.swift`
2. Set `defaultEndpoint`, `defaultModel`, `icon`, `subtitle`, `category`, `clientKind`
3. Done. The router, settings UI, and CLI all pick it up automatically.

If the new provider uses OpenAI-compatible API, set `clientKind = .openaiCompatible` and you're finished. For custom API formats, create a new client in `Services/`.

---

## 🤝 Contributing

Contributions are welcome! Here's how to get started:

```bash
# Fork and clone
git clone https://github.com/danwoo1234/ai-terminal.git
cd ai-terminal

# Build and run the .app
make run

# Or build and run the CLI
swift run ait -i
```

### Guidelines

- Keep PRs focused — one feature or fix per PR
- Follow existing code style (no SwiftLint enforced, just match the patterns)
- Test with at least one provider (Pollinations works without API keys)
- Update README if adding user-facing features

### Areas for Contribution

- 🐛 Bug fixes and stability improvements
- 🤖 New AI provider integrations
- 🎨 Terminal rendering improvements
- 📱 Linux / cross-platform support
- 🧪 Test coverage
- 📚 Documentation and examples

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

<div align="center">

**Built with Swift, SwiftUI, and a love for the terminal.**

[⬆ Back to top](#-ai-terminal)

</div>
