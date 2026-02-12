// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClawdVoice",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "ClawdVoice", targets: ["ClawdVoice"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "ClawdVoice",
            dependencies: ["KeyboardShortcuts"],
            path: "Sources"
        )
    ]
)
