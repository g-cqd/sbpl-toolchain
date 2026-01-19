// swift-tools-version: 6.2
import PackageDescription

let package = Package(
  name: "sbpl-toolchain",
  platforms: [
    .macOS(.v10_13),
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
    .library(
      name: "SBPLParser",
      targets: ["SBPLParser"]
    ),
    .library(
      name: "SBPLConverter",
      targets: ["SBPLConverter"]
    ),
    .executable(
      name: "sbpl-lex",
      targets: ["sbpl-lex"]
    ),
    .executable(
      name: "sbpl-convert",
      targets: ["sbpl-convert"]
    ),
  ],
  targets: [
    // Core types with no external dependencies
    .target(
      name: "SBPLCore",
      swiftSettings: swiftSettings
    ),
    // Lexer depends on SBPLCore
    .target(
      name: "SBPLLexer",
      dependencies: ["SBPLCore"],
      swiftSettings: swiftSettings
    ),
    // Parser depends on Lexer
    .target(
      name: "SBPLParser",
      dependencies: ["SBPLCore", "SBPLLexer"],
      swiftSettings: swiftSettings
    ),
    // Converter depends on Parser
    .target(
      name: "SBPLConverter",
      dependencies: ["SBPLCore", "SBPLParser"],
      swiftSettings: swiftSettings
    ),
    // CLI for testing lexer
    .executableTarget(
      name: "sbpl-lex",
      dependencies: ["SBPLLexer"],
      swiftSettings: swiftSettings
    ),
    // CLI for converting
    .executableTarget(
      name: "sbpl-convert",
      dependencies: ["SBPLConverter"],
      swiftSettings: swiftSettings
    ),
    // Tests
    .testTarget(
      name: "SBPLCoreTests",
      dependencies: ["SBPLCore"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SBPLLexerTests",
      dependencies: ["SBPLLexer"],
      resources: [
        .copy("../../Fixtures"),
      ],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SBPLParserTests",
      dependencies: ["SBPLParser"],
      swiftSettings: swiftSettings
    ),
    .testTarget(
      name: "SBPLConverterTests",
      dependencies: ["SBPLConverter"],
      swiftSettings: swiftSettings
    ),
  ],
  swiftLanguageModes: [.v6]
)

// MARK: - Swift Settings

let swiftSettings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("InternalImportsByDefault"),
]
