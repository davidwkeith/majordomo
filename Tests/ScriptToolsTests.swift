import Foundation
import Testing
@testable import Majordomo

// MARK: - ScriptTools Tests

private func makeTools(
    existingScripts: [Script] = [],
    toolNames: Set<String> = ["volume", "brightness", "screenshot", "clipboard"],
    executorResults: [JSONValue] = []
) throws -> ScriptTools {
    let io = MockScriptFileIO()
    if !existingScripts.isEmpty {
        io.existingData = try JSONEncoder().encode(existingScripts)
    }
    let executor = MockToolExecutor()
    executor.results = executorResults
    let lister = MockToolLister(toolNames: toolNames)
    return ScriptTools(
        store: ScriptStore(fileIO: io),
        executor: ScriptExecutor(toolExecutor: executor),
        toolLister: lister
    )
}

// MARK: - script_list

@Test func scriptListReturnsEmpty() throws {
    let tools = try makeTools()
    let result = tools.scriptList()
    #expect(result == .array([]))
}

@Test func scriptListReturnsScripts() throws {
    let scripts = [Script(id: "s1", name: "Test", description: "desc", steps: [])]
    let tools = try makeTools(existingScripts: scripts)
    let result = tools.scriptList()

    guard case .array(let items) = result else {
        Issue.record("Expected array")
        return
    }
    #expect(items.count == 1)
}

// MARK: - script_get

@Test func scriptGetReturnsScript() throws {
    let scripts = [Script(
        id: "s1", name: "Test", description: "desc",
        steps: [ScriptStep(tool: "volume", parameters: ["level": .int(50)])]
    )]
    let tools = try makeTools(existingScripts: scripts)
    let result = try tools.scriptGet(id: "s1")

    guard case .object(let obj) = result else {
        Issue.record("Expected object")
        return
    }
    #expect(obj["id"] == .string("s1"))
    #expect(obj["name"] == .string("Test"))
}

@Test func scriptGetThrowsForUnknown() throws {
    let tools = try makeTools()
    #expect(throws: ScriptStoreError.self) {
        try tools.scriptGet(id: "nonexistent")
    }
}

// MARK: - script_create

@Test func scriptCreateSucceeds() throws {
    var tools = try makeTools()
    let result = try tools.scriptCreate(
        name: "Morning",
        description: "Morning routine",
        steps: [ScriptStep(tool: "volume", parameters: ["level": .int(30)])]
    )

    guard case .object(let obj) = result else {
        Issue.record("Expected object")
        return
    }
    #expect(obj["name"] == .string("Morning"))
    #expect(tools.scriptList() != .array([]))
}

@Test func scriptCreateRejectsUnknownTool() throws {
    var tools = try makeTools(toolNames: ["volume"])
    #expect(throws: ScriptToolsError.self) {
        try tools.scriptCreate(
            name: "Bad",
            description: "Uses unknown tool",
            steps: [ScriptStep(tool: "nonexistent_tool", parameters: [:])]
        )
    }
}

@Test func scriptCreateRejectsEmptySteps() throws {
    var tools = try makeTools()
    #expect(throws: ScriptToolsError.self) {
        try tools.scriptCreate(name: "Empty", description: "No steps", steps: [])
    }
}

// MARK: - script_delete

@Test func scriptDeleteSucceeds() throws {
    let scripts = [Script(id: "s1", name: "Test", description: "desc", steps: [])]
    var tools = try makeTools(existingScripts: scripts)
    let result = try tools.scriptDelete(id: "s1")
    #expect(result == .object(["deleted": .string("s1")]))
    #expect(tools.scriptList() == .array([]))
}

@Test func scriptDeleteThrowsForUnknown() throws {
    var tools = try makeTools()
    #expect(throws: ScriptStoreError.self) {
        try tools.scriptDelete(id: "nonexistent")
    }
}

// MARK: - script_run

@Test func scriptRunExecutesScript() async throws {
    let scripts = [Script(
        id: "s1", name: "Test", description: "desc",
        steps: [ScriptStep(tool: "volume", parameters: ["level": .int(50)])]
    )]
    var tools = try makeTools(existingScripts: scripts, executorResults: [.string("ok")])
    let result = try await tools.scriptRun(id: "s1")

    guard case .object(let obj) = result else {
        Issue.record("Expected object")
        return
    }
    #expect(obj["script_id"] == .string("s1"))
    guard case .array(let results) = obj["results"] else {
        Issue.record("Expected results array")
        return
    }
    #expect(results.count == 1)
    #expect(results[0] == .string("ok"))
}

@Test func scriptRunThrowsForUnknown() async throws {
    var tools = try makeTools()
    await #expect(throws: ScriptStoreError.self) {
        try await tools.scriptRun(id: "nonexistent")
    }
}

// MARK: - script_suggestions

@Test func scriptSuggestionsReturnsArray() throws {
    let tools = try makeTools()
    let result = tools.scriptSuggestions()
    guard case .array = result else {
        Issue.record("Expected array")
        return
    }
}

@Test func scriptSuggestionsIncludesRelevantSuggestions() throws {
    let tools = try makeTools(toolNames: ["system_volume", "system_brightness"])
    let result = tools.scriptSuggestions()

    guard case .array(let items) = result else {
        Issue.record("Expected array")
        return
    }
    // Should suggest something given these tools are available
    #expect(!items.isEmpty)
}
