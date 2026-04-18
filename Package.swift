// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AITerminal",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "ai-terminal", targets: ["AITerminal"]),
        .executable(name: "ait", targets: ["AITerminalCLI"]),
    ],
    targets: [
        .target(
            name: "CPty",
            path: "Sources/CPty",
            publicHeadersPath: "include"
        ),
        .executableTarget(
            name: "AITerminal",
            dependencies: ["CPty"],
            path: "Sources/AITerminal",
            exclude: ["Resources/Info.plist"]
        ),
        .executableTarget(
            name: "AITerminalCLI",
            path: "Sources/AITerminalCLI"
        )
    ]
)
