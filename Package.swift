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
      name: "SBPLCore"
    ),
    // Lexer depends on SBPLCore
    .target(
      name: "SBPLLexer",
      dependencies: ["SBPLCore"]
    ),
    // Parser depends on Lexer
    .target(
      name: "SBPLParser",
      dependencies: ["SBPLCore", "SBPLLexer"]
    ),
    // Converter depends on Parser
    .target(
      name: "SBPLConverter",
      dependencies: ["SBPLCore", "SBPLParser"]
    ),
    // CLI for testing lexer
    .executableTarget(
      name: "sbpl-lex",
      dependencies: ["SBPLLexer"]
    ),
    // CLI for converting
    .executableTarget(
      name: "sbpl-convert",
      dependencies: ["SBPLConverter"]
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
    .testTarget(
      name: "SBPLParserTests",
      dependencies: ["SBPLParser"]
    ),
    .testTarget(
      name: "SBPLConverterTests",
      dependencies: ["SBPLConverter"]
    ),
  ]
)
