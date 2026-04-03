import Foundation

/// Generates MCP tool definitions from declared device capabilities.
enum CapabilityToolGenerator {

    /// Generate get/set tools for a single capability.
    static func generateTools(
        capabilityName: String,
        spec: CapabilitySpec,
        prefix: String?
    ) -> [ToolDefinition] {
        let qualifiedName: (String) -> String = { action in
            if let prefix {
                return "\(prefix)_\(action)_\(capabilityName)"
            }
            return "\(action)_\(capabilityName)"
        }

        var tools: [ToolDefinition] = []

        // Always generate a get tool
        let getDescription = buildGetDescription(capabilityName: capabilityName, spec: spec)
        tools.append(ToolDefinition(
            name: qualifiedName("get"),
            description: getDescription,
            handler: nil,
            annotations: ["readOnlyHint": true]
        ))

        // Generate set tool only if not readonly
        if spec.readonly != true {
            let setDescription = buildSetDescription(capabilityName: capabilityName, spec: spec)
            tools.append(ToolDefinition(
                name: qualifiedName("set"),
                description: setDescription,
                handler: nil,
                annotations: ["readOnlyHint": false]
            ))
        }

        return tools
    }

    /// Generate tools for all capabilities declared in a manifest.
    static func generateAllTools(from manifest: EndpointManifest) -> [ToolDefinition] {
        guard let capabilities = manifest.capabilities else { return [] }

        return capabilities
            .sorted { $0.key < $1.key }
            .flatMap { name, spec in
                generateTools(capabilityName: name, spec: spec, prefix: manifest.toolPrefix)
            }
    }

    // MARK: - Description builders

    private static func buildGetDescription(capabilityName: String, spec: CapabilitySpec) -> String {
        var desc = "Get the current \(capabilityName) value."
        if let unit = spec.unit {
            desc += " Unit: \(unit)."
        }
        if let min = spec.min, let max = spec.max {
            desc += " Range: \(formatNumber(min))–\(formatNumber(max))."
        }
        return desc
    }

    private static func buildSetDescription(capabilityName: String, spec: CapabilitySpec) -> String {
        var desc = "Set the \(capabilityName) value."
        if spec.type == "boolean" {
            desc += " Accepts true or false."
        }
        if let min = spec.min, let max = spec.max {
            desc += " Range: \(formatNumber(min))–\(formatNumber(max))."
        }
        if let enumValues = spec.enumValues {
            desc += " Allowed values: \(enumValues.joined(separator: ", "))."
        }
        return desc
    }

    private static func formatNumber(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(value)
    }
}
