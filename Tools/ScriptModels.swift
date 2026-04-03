import Foundation

/// Type-safe JSON value that is Codable, Sendable, and Equatable.
/// Used for script step parameters and execution results.
enum JSONValue: Codable, Sendable, Equatable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([JSONValue])
    case object([String: JSONValue])
    case null

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode JSONValue"
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

/// A single step in a script pipeline.
struct ScriptStep: Codable, Sendable, Equatable {
    /// The tool name to invoke (e.g. "system_volume").
    let tool: String
    /// Parameters to pass to the tool. May contain template variables like `{{steps.0.result}}`.
    let parameters: [String: JSONValue]
}

/// A saved script — a reusable sequence of tool calls.
struct Script: Codable, Sendable, Equatable {
    /// Unique identifier for this script.
    let id: String
    /// Human-readable name.
    let name: String
    /// Description of what the script does.
    let description: String
    /// Ordered steps to execute.
    let steps: [ScriptStep]
}

// MARK: - Template Resolution

/// Pattern matching `{{steps.N.result}}` where N is a zero-based step index.
private nonisolated(unsafe) let templatePattern = try! Regex(#"\{\{steps\.(\d+)\.result\}\}"#)

/// Resolve template variables in a parameter dictionary.
/// - Parameters:
///   - params: The parameters potentially containing `{{steps.N.result}}` templates.
///   - stepResults: Results from previously executed steps, indexed by position.
/// - Returns: A new parameter dictionary with templates replaced by actual values.
func resolveTemplates(in params: [String: JSONValue], stepResults: [JSONValue]) -> [String: JSONValue] {
    params.mapValues { resolveValue($0, stepResults: stepResults) }
}

private func resolveValue(_ value: JSONValue, stepResults: [JSONValue]) -> JSONValue {
    switch value {
    case .string(let str):
        return resolveStringTemplate(str, stepResults: stepResults)
    case .array(let items):
        return .array(items.map { resolveValue($0, stepResults: stepResults) })
    case .object(let dict):
        return .object(dict.mapValues { resolveValue($0, stepResults: stepResults) })
    default:
        return value
    }
}

private func resolveStringTemplate(_ str: String, stepResults: [JSONValue]) -> JSONValue {
    // Check if the entire string is a single template reference (preserve type).
    if let match = try? templatePattern.wholeMatch(in: str),
       let indexSubstring = match[1].substring,
       let index = Int(indexSubstring) {
        guard index < stepResults.count else { return .string(str) }
        return stepResults[index]
    }

    // Otherwise, do string interpolation for embedded references.
    var result = str
    for match in str.matches(of: templatePattern).reversed() {
        guard let indexSubstring = match[1].substring,
              let index = Int(indexSubstring) else { continue }
        guard index < stepResults.count else { continue }
        let replacement = stringifyJSONValue(stepResults[index])
        result = result.replacingCharacters(in: match.range, with: replacement)
    }
    return .string(result)
}

/// Convert a JSONValue to its string representation for interpolation.
private func stringifyJSONValue(_ value: JSONValue) -> String {
    switch value {
    case .string(let s): return s
    case .int(let i): return String(i)
    case .double(let d): return String(d)
    case .bool(let b): return String(b)
    case .null: return "null"
    case .array, .object:
        guard let data = try? JSONEncoder().encode(value),
              let str = String(data: data, encoding: .utf8) else { return "" }
        return str
    }
}
