import Foundation
import Testing
@testable import Majordomo

// MARK: - ScriptExecutor Tests

@Test func executorRunsSingleStep() async throws {
    let mock = MockToolExecutor()
    mock.results = [.string("done")]
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(
        id: "s1", name: "Test", description: "desc",
        steps: [ScriptStep(tool: "volume", parameters: ["level": .int(50)])]
    )
    let results = try await executor.run(script)

    #expect(results.count == 1)
    #expect(results[0] == .string("done"))
    #expect(mock.calls.count == 1)
    #expect(mock.calls[0].tool == "volume")
    #expect(mock.calls[0].parameters == ["level": .int(50)])
}

@Test func executorRunsMultipleStepsSequentially() async throws {
    let mock = MockToolExecutor()
    mock.results = [.string("first"), .string("second")]
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(
        id: "s1", name: "Test", description: "desc",
        steps: [
            ScriptStep(tool: "step_a", parameters: [:]),
            ScriptStep(tool: "step_b", parameters: [:])
        ]
    )
    let results = try await executor.run(script)

    #expect(results.count == 2)
    #expect(results[0] == .string("first"))
    #expect(results[1] == .string("second"))
    #expect(mock.calls[0].tool == "step_a")
    #expect(mock.calls[1].tool == "step_b")
}

@Test func executorResolvesTemplatesBetweenSteps() async throws {
    let mock = MockToolExecutor()
    mock.results = [.string("screenshot.png"), .string("copied")]
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(
        id: "s1", name: "Capture", description: "desc",
        steps: [
            ScriptStep(tool: "screenshot", parameters: [:]),
            ScriptStep(tool: "clipboard", parameters: ["text": .string("{{steps.0.result}}")])
        ]
    )
    _ = try await executor.run(script)

    // The second step should have received the resolved template
    #expect(mock.calls[1].parameters["text"] == .string("screenshot.png"))
}

@Test func executorPreservesTypeInTemplateResolution() async throws {
    let mock = MockToolExecutor()
    mock.results = [.int(75), .null]
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(
        id: "s1", name: "Test", description: "desc",
        steps: [
            ScriptStep(tool: "get_volume", parameters: [:]),
            ScriptStep(tool: "set_volume", parameters: ["level": .string("{{steps.0.result}}")])
        ]
    )
    _ = try await executor.run(script)

    #expect(mock.calls[1].parameters["level"] == .int(75))
}

@Test func executorPropagatesToolErrors() async throws {
    let mock = MockToolExecutor()
    mock.error = ScriptExecutionError.toolFailed(tool: "bad_tool", reason: "not found")
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(
        id: "s1", name: "Test", description: "desc",
        steps: [ScriptStep(tool: "bad_tool", parameters: [:])]
    )

    await #expect(throws: ScriptExecutionError.self) {
        try await executor.run(script)
    }
}

@Test func executorReturnsEmptyForEmptyScript() async throws {
    let mock = MockToolExecutor()
    let executor = ScriptExecutor(toolExecutor: mock)

    let script = Script(id: "s1", name: "Empty", description: "desc", steps: [])
    let results = try await executor.run(script)

    #expect(results.isEmpty)
    #expect(mock.calls.isEmpty)
}
