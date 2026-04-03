import Foundation

/// Decoded representation of a `.majordomo-plugin/manifest.json`.
struct EndpointManifest: Codable, Sendable {
    let name: String
    let id: String
    let type: String
    let version: String
    let description: String
    let endpoint: EndpointBlock
    let tools: [ToolDefinition]?
    let prompts: [PromptReference]?
    let toolPrefix: String?
    let capabilities: [String: CapabilitySpec]?

    enum CodingKeys: String, CodingKey {
        case name, id, type, version, description, endpoint, tools, prompts
        case toolPrefix = "tool_prefix"
        case capabilities
    }
}

/// The `endpoint` block describing how to reach the service.
struct EndpointBlock: Codable, Sendable {
    let type: String
    let address: String?
    let baseURL: String?
    let label: String?
    let auth: AuthConfig?

    enum CodingKeys: String, CodingKey {
        case type, address, label, auth
        case baseURL = "base_url"
    }
}

/// Authentication configuration for an endpoint.
struct AuthConfig: Codable, Sendable {
    let type: String
    let keychainKey: String?

    enum CodingKeys: String, CodingKey {
        case type
        case keychainKey = "keychain_key"
    }
}

/// A tool declared in the manifest.
struct ToolDefinition: Codable, Sendable {
    let name: String
    let description: String
    let handler: String?
    let annotations: [String: Bool]?
}

/// A prompt file reference in the manifest.
struct PromptReference: Codable, Sendable {
    let type: String
    let file: String
    let description: String?
}

/// Specification for a single device capability.
struct CapabilitySpec: Codable, Sendable {
    let type: String
    let min: Double?
    let max: Double?
    let unit: String?
    let readonly: Bool?
    let enumValues: [String]?

    enum CodingKeys: String, CodingKey {
        case type, min, max, unit, readonly
        case enumValues = "enum"
    }
}
