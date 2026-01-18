// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "sbpl-toolchain",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
  ],
  products: [
    .library(
      name: "SBPLCore",
      targets: ["SBPLCore"]
    ),
    .library(
      name: "SBPLLexer",
      targets: ["SBPLLexer"]
    ),
    .executable(
      name: "sbpl-lex",
      targets: ["sbpl-lex"]
    ),
  ],
  targets: [
    // Core types with no external dependencies
    .target(
      name: "SBPLCore"
    ),
    // Lexer depends on SBPLCore
    .target(
      name: "SBPLLexer",
      dependencies: ["SBPLCore"]
    ),
    // CLI for testing lexer
    .executableTarget(
      name: "sbpl-lex",
      dependencies: ["SBPLLexer"]
    ),
    // Tests
    .testTarget(
      name: "SBPLCoreTests",
      dependencies: ["SBPLCore"]
    ),
    .testTarget(
      name: "SBPLLexerTests",
      dependencies: ["SBPLLexer"],
      resources: [
        .copy("../../Fixtures"),
      ]
    ),
  ]
)
