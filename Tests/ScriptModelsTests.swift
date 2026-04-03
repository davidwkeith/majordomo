import Foundation
import Testing
@testable import Majordomo

// MARK: - JSONValue Tests

@Test func jsonValueEncodesString() throws {
    let value = JSONValue.string("hello")
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .string("hello"))
}

@Test func jsonValueEncodesInt() throws {
    let value = JSONValue.int(42)
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .int(42))
}

@Test func jsonValueEncodesBool() throws {
    let value = JSONValue.bool(true)
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .bool(true))
}

@Test func jsonValueEncodesNull() throws {
    let value = JSONValue.null
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .null)
}

@Test func jsonValueEncodesDouble() throws {
    let value = JSONValue.double(3.14)
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .double(3.14))
}

@Test func jsonValueEncodesArray() throws {
    let value = JSONValue.array([.string("a"), .int(1), .bool(false)])
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .array([.string("a"), .int(1), .bool(false)]))
}

@Test func jsonValueEncodesObject() throws {
    let value = JSONValue.object(["key": .string("value"), "num": .int(5)])
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == .object(["key": .string("value"), "num": .int(5)]))
}

@Test func jsonValueEncodesNestedStructures() throws {
    let value = JSONValue.object([
        "items": .array([
            .object(["name": .string("test"), "count": .int(3)])
        ]),
        "active": .bool(true)
    ])
    let data = try JSONEncoder().encode(value)
    let decoded = try JSONDecoder().decode(JSONValue.self, from: data)
    #expect(decoded == value)
}

// MARK: - ScriptStep Tests

@Test func scriptStepRoundTrips() throws {
    let step = ScriptStep(
        tool: "system_volume",
        parameters: ["level": .int(50)]
    )
    let data = try JSONEncoder().encode(step)
    let decoded = try JSONDecoder().decode(ScriptStep.self, from: data)
    #expect(decoded.tool == "system_volume")
    #expect(decoded.parameters == ["level": .int(50)])
}

@Test func scriptStepWithTemplateVariable() throws {
    let step = ScriptStep(
        tool: "clipboard_write",
        parameters: ["text": .string("{{steps.0.result}}")]
    )
    let data = try JSONEncoder().encode(step)
    let decoded = try JSONDecoder().decode(ScriptStep.self, from: data)
    #expect(decoded.parameters["text"] == .string("{{steps.0.result}}"))
}

// MARK: - Script Tests

@Test func scriptRoundTrips() throws {
    let script = Script(
        id: "test-id",
        name: "Morning Routine",
        description: "Set up morning defaults",
        steps: [
            ScriptStep(tool: "system_volume", parameters: ["level": .int(30)]),
            ScriptStep(tool: "system_brightness", parameters: ["level": .int(80)])
        ]
    )
    let data = try JSONEncoder().encode(script)
    let decoded = try JSONDecoder().decode(Script.self, from: data)
    #expect(decoded.id == "test-id")
    #expect(decoded.name == "Morning Routine")
    #expect(decoded.description == "Set up morning defaults")
    #expect(decoded.steps.count == 2)
    #expect(decoded.steps[0].tool == "system_volume")
    #expect(decoded.steps[1].tool == "system_brightness")
}

@Test func scriptDecodesFromJSON() throws {
    let json = """
    {
      "id": "abc-123",
      "name": "Quick Capture",
      "description": "Screenshot and copy to clipboard",
      "steps": [
        { "tool": "screenshot_capture", "parameters": {} },
        { "tool": "clipboard_write", "parameters": { "text": "{{steps.0.result}}" } }
      ]
    }
    """.data(using: .utf8)!

    let script = try JSONDecoder().decode(Script.self, from: json)
    #expect(script.id == "abc-123")
    #expect(script.name == "Quick Capture")
    #expect(script.steps.count == 2)
    #expect(script.steps[1].parameters["text"] == .string("{{steps.0.result}}"))
}

@Test func scriptWithEmptySteps() throws {
    let script = Script(id: "empty", name: "Empty", description: "No steps", steps: [])
    let data = try JSONEncoder().encode(script)
    let decoded = try JSONDecoder().decode(Script.self, from: data)
    #expect(decoded.steps.isEmpty)
}

// MARK: - Template Resolution Tests

@Test func resolveTemplateReplacesWholeValue() {
    let params: [String: JSONValue] = ["text": .string("{{steps.0.result}}")]
    let results: [JSONValue] = [.string("clipboard content")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("clipboard content"))
}

@Test func resolveTemplatePreservesNonStringTypes() {
    let params: [String: JSONValue] = ["text": .string("{{steps.0.result}}")]
    let results: [JSONValue] = [.int(42)]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .int(42))
}

@Test func resolveTemplateInterpolatesWithinString() {
    let params: [String: JSONValue] = ["text": .string("Result: {{steps.0.result}} done")]
    let results: [JSONValue] = [.string("success")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("Result: success done"))
}

@Test func resolveTemplateHandlesMultipleReferences() {
    let params: [String: JSONValue] = [
        "text": .string("{{steps.0.result}} and {{steps.1.result}}")
    ]
    let results: [JSONValue] = [.string("first"), .string("second")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("first and second"))
}

@Test func resolveTemplateRecursesIntoObjects() {
    let params: [String: JSONValue] = [
        "body": .object(["inner": .string("{{steps.0.result}}")])
    ]
    let results: [JSONValue] = [.string("replaced")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["body"] == .object(["inner": .string("replaced")]))
}

@Test func resolveTemplateRecursesIntoArrays() {
    let params: [String: JSONValue] = [
        "items": .array([.string("{{steps.0.result}}"), .string("static")])
    ]
    let results: [JSONValue] = [.string("dynamic")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["items"] == .array([.string("dynamic"), .string("static")]))
}

@Test func resolveTemplateIgnoresOutOfBoundsIndex() {
    let params: [String: JSONValue] = ["text": .string("{{steps.5.result}}")]
    let results: [JSONValue] = [.string("only one")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("{{steps.5.result}}"))
}

@Test func resolveTemplateLeavesNonTemplateStringsAlone() {
    let params: [String: JSONValue] = [
        "level": .int(50),
        "name": .string("no templates here")
    ]
    let results: [JSONValue] = [.string("unused")]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["level"] == .int(50))
    #expect(resolved["name"] == .string("no templates here"))
}

@Test func resolveTemplateWithEmptyResults() {
    let params: [String: JSONValue] = ["text": .string("{{steps.0.result}}")]
    let results: [JSONValue] = []

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("{{steps.0.result}}"))
}

@Test func resolveTemplateStringifiesNonStringInInterpolation() {
    let params: [String: JSONValue] = ["text": .string("count: {{steps.0.result}}")]
    let results: [JSONValue] = [.int(42)]

    let resolved = resolveTemplates(in: params, stepResults: results)
    #expect(resolved["text"] == .string("count: 42"))
}
