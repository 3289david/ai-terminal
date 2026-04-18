# ╔══════════════════════════════════════════════════════════════╗
# ║  AI Terminal — Makefile                                      ║
# ╚══════════════════════════════════════════════════════════════╝

.PHONY: build app dmg install clean run cli

# Build release binary
build:
	swift build -c release

# Build .app bundle
app:
	@chmod +x Scripts/build-app.sh
	@bash Scripts/build-app.sh

# Build .dmg installer
dmg: app
	@chmod +x Scripts/make-dmg.sh
	@bash Scripts/make-dmg.sh

# Install to /Applications
install: app
	@echo "  Installing AI Terminal.app to /Applications..."
	@cp -R ".build/AI Terminal.app" /Applications/
	@echo "  ✅ Installed to /Applications/AI Terminal.app"

# Run the app
run: app
	@open ".build/AI Terminal.app"

# Build CLI only
cli:
	swift build -c release --product ait
	@echo ""
	@echo "  CLI binary: .build/release/ait"
	@echo "  Install:    cp .build/release/ait /usr/local/bin/"

# Install CLI
install-cli: cli
	@cp .build/release/ait /usr/local/bin/ait
	@echo "  ✅ Installed ait to /usr/local/bin/"

# Clean build artifacts
clean:
	swift package clean
	rm -rf .build/AI\ Terminal.app
	rm -f .build/AI\ Terminal-*.dmg

# Run tests (if any)
test:
	swift test

# Show help
help:
	@echo ""
	@echo "  AI Terminal — Build Targets"
	@echo "  ─────────────────────────────"
	@echo "  make app          Build AI Terminal.app"
	@echo "  make dmg          Build AI Terminal-2.0.0.dmg installer"
	@echo "  make install      Build and install to /Applications"
	@echo "  make run          Build and launch"
	@echo "  make cli          Build CLI (ait) only"
	@echo "  make install-cli  Build and install CLI to /usr/local/bin"
	@echo "  make clean        Remove build artifacts"
	@echo ""
