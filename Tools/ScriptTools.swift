import Foundation

/// Errors from script tool operations.
enum ScriptToolsError: Error, Equatable {
    case unknownTool(String)
    case emptySteps
}

/// Protocol for querying available tool names (for validation).
protocol ToolListing {
    func availableToolNames() -> Set<String>
}

/// Mock tool lister for testing.
final class MockToolLister: ToolListing {
    let toolNames: Set<String>
    init(toolNames: Set<String>) { self.toolNames = toolNames }
    func availableToolNames() -> Set<String> { toolNames }
}

/// Saved scripts — storage and management tools.
/// Exposes script_list, script_get, script_run, script_create, script_delete, script_suggestions.
struct ScriptTools {
    private(set) var store: ScriptStore
    private let executor: ScriptExecutor
    private let toolLister: ToolListing

    init(store: ScriptStore, executor: ScriptExecutor, toolLister: ToolListing) {
        self.store = store
        self.executor = executor
        self.toolLister = toolLister
    }

    // MARK: - script_list

    /// List all saved scripts with their IDs, names, and descriptions.
    func scriptList() -> JSONValue {
        let scripts = store.list()
        let items = scripts.map { script -> JSONValue in
            .object([
                "id": .string(script.id),
                "name": .string(script.name),
                "description": .string(script.description),
                "step_count": .int(script.steps.count)
            ])
        }
        return .array(items)
    }

    // MARK: - script_get

    /// Get full details of a script by ID.
    func scriptGet(id: String) throws -> JSONValue {
        guard let script = store.get(id: id) else {
            throw ScriptStoreError.notFound(id)
        }
        return scriptToJSON(script)
    }

    // MARK: - script_create

    /// Create a new script. Validates that all referenced tool names exist.
    mutating func scriptCreate(name: String, description: String, steps: [ScriptStep]) throws -> JSONValue {
        guard !steps.isEmpty else {
            throw ScriptToolsError.emptySteps
        }

        let availableTools = toolLister.availableToolNames()
        for step in steps {
            if !availableTools.contains(step.tool) {
                throw ScriptToolsError.unknownTool(step.tool)
            }
        }

        let script = Script(
            id: UUID().uuidString,
            name: name,
            description: description,
            steps: steps
        )
        try store.create(script)
        return scriptToJSON(script)
    }

    // MARK: - script_delete

    /// Delete a script by ID.
    mutating func scriptDelete(id: String) throws -> JSONValue {
        try store.delete(id: id)
        return .object(["deleted": .string(id)])
    }

    // MARK: - script_run

    /// Execute a saved script by ID.
    mutating func scriptRun(id: String) async throws -> JSONValue {
        guard let script = store.get(id: id) else {
            throw ScriptStoreError.notFound(id)
        }
        let results = try await executor.run(script)
        return .object([
            "script_id": .string(script.id),
            "script_name": .string(script.name),
            "results": .array(results)
        ])
    }

    // MARK: - script_suggestions

    /// Suggest scripts based on available tools.
    func scriptSuggestions() -> JSONValue {
        let available = toolLister.availableToolNames()
        var suggestions: [JSONValue] = []

        // Suggest a "morning routine" if volume and brightness tools exist
        let hasVolume = available.contains { $0.contains("volume") }
        let hasBrightness = available.contains { $0.contains("brightness") }
        if hasVolume && hasBrightness {
            suggestions.append(.object([
                "name": .string("Morning Routine"),
                "description": .string("Set volume and brightness to comfortable levels"),
                "tools_used": .array([.string("volume"), .string("brightness")])
            ]))
        }

        // Suggest a "quick capture" if screenshot and clipboard tools exist
        let hasScreenshot = available.contains { $0.contains("screenshot") }
        let hasClipboard = available.contains { $0.contains("clipboard") }
        if hasScreenshot && hasClipboard {
            suggestions.append(.object([
                "name": .string("Quick Capture"),
                "description": .string("Take a screenshot and copy the path to clipboard"),
                "tools_used": .array([.string("screenshot"), .string("clipboard")])
            ]))
        }

        // Suggest a "focus mode" if volume and notification tools exist
        let hasNotification = available.contains { $0.contains("notification") }
        if hasVolume && hasNotification {
            suggestions.append(.object([
                "name": .string("Focus Mode"),
                "description": .string("Mute volume and pause notifications"),
                "tools_used": .array([.string("volume"), .string("notification")])
            ]))
        }

        return .array(suggestions)
    }

    // MARK: - Helpers

    private func scriptToJSON(_ script: Script) -> JSONValue {
        let stepsJSON = script.steps.map { step -> JSONValue in
            .object([
                "tool": .string(step.tool),
                "parameters": .object(step.parameters)
            ])
        }
        return .object([
            "id": .string(script.id),
            "name": .string(script.name),
            "description": .string(script.description),
            "steps": .array(stepsJSON)
        ])
    }
}
