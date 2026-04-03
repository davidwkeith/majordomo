import Foundation

/// Errors from script execution.
enum ScriptExecutionError: Error, Equatable {
    case toolFailed(tool: String, reason: String)
}

/// Protocol for executing a single tool call.
protocol ToolExecuting: Sendable {
    func execute(tool: String, parameters: [String: JSONValue]) async throws -> JSONValue
}

/// Records tool calls for testing.
final class MockToolExecutor: ToolExecuting, @unchecked Sendable {
    struct Call: Equatable {
        let tool: String
        let parameters: [String: JSONValue]
    }

    var results: [JSONValue] = []
    var error: ScriptExecutionError?
    private(set) var calls: [Call] = []

    func execute(tool: String, parameters: [String: JSONValue]) async throws -> JSONValue {
        calls.append(Call(tool: tool, parameters: parameters))
        if let error { throw error }
        let index = calls.count - 1
        return index < results.count ? results[index] : .null
    }
}

/// Executes a script by replaying tool calls sequentially with template resolution.
struct ScriptExecutor: Sendable {
    private let toolExecutor: ToolExecuting

    init(toolExecutor: ToolExecuting) {
        self.toolExecutor = toolExecutor
    }

    /// Run all steps in the script sequentially, resolving templates between steps.
    /// - Returns: Array of results from each step.
    func run(_ script: Script) async throws -> [JSONValue] {
        var stepResults: [JSONValue] = []

        for step in script.steps {
            let resolvedParams = resolveTemplates(in: step.parameters, stepResults: stepResults)
            let result = try await toolExecutor.execute(tool: step.tool, parameters: resolvedParams)
            stepResults.append(result)
        }

        return stepResults
    }
}
