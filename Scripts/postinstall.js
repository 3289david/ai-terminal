"use strict";

const { execSync } = require("child_process");
const path = require("path");
const fs = require("fs");
const os = require("os");

const projectRoot = path.resolve(__dirname, "..");
const nativeBin = path.join(projectRoot, ".build", "release", "ait");

// Only supported on macOS
if (os.platform() !== "darwin") {
  console.warn(
    "\n  ⚠ ai-terminal-app requires macOS 14+ and Swift 5.9+." +
    "\n  The npm wrapper is installed but the native binary cannot be built on this platform.\n"
  );
  process.exit(0);
}

// Check if Swift is available
try {
  execSync("swift --version", { stdio: "ignore" });
} catch {
  console.warn(
    "\n  ⚠ Swift not found. Install Xcode or Swift toolchain from https://swift.org/download" +
    "\n  Then run: cd " + projectRoot + " && swift build -c release --product ait\n"
  );
  process.exit(0);
}

// Build the native binary
console.log("\n  ⚡ Building AI Terminal CLI (ait) from source...\n");
try {
  execSync("swift build -c release --product ait", {
    cwd: projectRoot,
    stdio: "inherit",
  });
  if (fs.existsSync(nativeBin)) {
    console.log("\n  ✅ ait CLI built successfully!");
    console.log("  Binary: " + nativeBin);
    console.log("  Run: npx ait --help\n");
  }
} catch (e) {
  console.error(
    "\n  ✕ Build failed. Make sure you have Xcode and Swift 5.9+ installed." +
    "\n  You can build manually: cd " + projectRoot + " && swift build -c release --product ait\n"
  );
  process.exit(0); // Don't fail npm install
}
