// swift-tools-version: 5.10
// © Copyright, 2026 David L. Collison, All Rights Reserved.
import PackageDescription

let package = Package(
    name: "translate-strings",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "translate-strings", path: "Sources/translate-strings"),
        .testTarget(name: "translate-strings-tests", dependencies: ["translate-strings"], path: "Tests/translate-strings-tests")
    ]
)
