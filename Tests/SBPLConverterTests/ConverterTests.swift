import Testing
import Foundation

@testable import SBPLConverter
@testable import SBPLCore

@Suite("SBPL to JSON Tests")
struct SBPLToJSONTests {
  @Test("Convert simple profile")
  func testConvertSimpleProfile() {
    let source = """
      (version 1)
      (deny default)
      """
    let converter = SBPLToJSON()
    let result = converter.convert(source: source)

    #expect(!result.hasErrors)
    #expect(result.profile?.version == 1)
    #expect(result.profile?.rules?.count == 1)
  }

  @Test("Convert to JSON string")
  func testConvertToJSONString() {
    let source = "(version 1)"
    let converter = SBPLToJSON()
    let (json, diagnostics) = converter.convertToString(source: source)

    #expect(diagnostics.isEmpty)
    #expect(json != nil)
    #expect(json?.contains("\"version\"") == true)
    #expect(json?.contains("1") == true)
  }

  @Test("Convert rule with filters")
  func testConvertRuleWithFilters() {
    let source = """
      (allow file-read-data
        (literal "/etc/passwd"))
      """
    let converter = SBPLToJSON()
    let result = converter.convert(source: source)

    #expect(!result.hasErrors)
    #expect(result.profile?.rules?.count == 1)
    #expect(result.profile?.rules?[0].filters?.count == 1)
    #expect(result.profile?.rules?[0].filters?[0].type == "literal")
  }

  @Test("Convert imports")
  func testConvertImports() {
    let source = """
      (import "system.sb")
      (import "common.sb")
      """
    let converter = SBPLToJSON()
    let result = converter.convert(source: source)

    #expect(!result.hasErrors)
    #expect(result.profile?.imports?.count == 2)
    #expect(result.profile?.imports?[0] == "system.sb")
    #expect(result.profile?.imports?[1] == "common.sb")
  }
}

@Suite("JSON to SBPL Tests")
struct JSONToSBPLTests {
  @Test("Convert simple profile")
  func testConvertSimpleProfile() {
    let profile = ProfileJSON(version: 1)
    let converter = JSONToSBPL()
    let sbpl = converter.convert(profile)

    #expect(sbpl.contains("(version 1)"))
  }

  @Test("Convert rule")
  func testConvertRule() {
    let profile = ProfileJSON(
      rules: [
        RuleJSON(action: "allow", operations: ["file-read-data"])
      ]
    )
    let converter = JSONToSBPL()
    let sbpl = converter.convert(profile)

    #expect(sbpl.contains("(allow file-read-data)"))
  }

  @Test("Convert rule with filter")
  func testConvertRuleWithFilter() {
    let profile = ProfileJSON(
      rules: [
        RuleJSON(
          action: "allow",
          operations: ["file-read-data"],
          filters: [
            FilterJSON(type: "literal", value: .string("/etc/passwd"))
          ]
        )
      ]
    )
    let converter = JSONToSBPL()
    let sbpl = converter.convert(profile)

    #expect(sbpl.contains("literal"))
    #expect(sbpl.contains("/etc/passwd"))
  }

  @Test("Convert from JSON string")
  func testConvertFromJSONString() throws {
    let json = """
      {
        "version": 1,
        "rules": [
          {
            "action": "deny",
            "operations": ["default"]
          }
        ]
      }
      """
    let converter = JSONToSBPL()
    let sbpl = try converter.convert(jsonString: json)

    #expect(sbpl.contains("(version 1)"))
    #expect(sbpl.contains("(deny default)"))
  }
}

@Suite("Round-trip Tests")
struct RoundtripTests {
  @Test("SBPL to JSON to SBPL")
  func testRoundtrip() throws {
    let originalSBPL = """
      (version 1)

      (import "system.sb")

      (deny default)

      (allow file-read-data
        (subpath "/usr"))
      """

    // Convert to JSON
    let toJSON = SBPLToJSON()
    let (json, diag1) = toJSON.convertToString(source: originalSBPL)
    #expect(diag1.isEmpty)
    #expect(json != nil)

    // Convert back to SBPL
    let toSBPL = JSONToSBPL()
    let convertedSBPL = try toSBPL.convert(jsonString: json!)

    // Verify key elements are preserved
    #expect(convertedSBPL.contains("(version 1)"))
    #expect(convertedSBPL.contains("(import \"system.sb\")"))
    #expect(convertedSBPL.contains("(deny default)"))
    #expect(convertedSBPL.contains("file-read-data"))
    #expect(convertedSBPL.contains("subpath"))
    #expect(convertedSBPL.contains("/usr"))
  }
}
