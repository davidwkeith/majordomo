import Foundation

/// Represents a detected MCP client.
struct MCPClient {
    let name: String
    let configPath: String
    let bundleIdentifier: String?
}

/// Protocol for filesystem access (injectable for testing).
protocol FileExistence {
    func fileExists(atPath path: String) -> Bool
}

extension FileManager: FileExistence {}

/// Scans the filesystem for known MCP client config files and returns which clients are installed.
struct MCPClientDetector {
    private let fileChecker: FileExistence
    private let homeDirectory: String

    init(fileChecker: FileExistence = FileManager.default, homeDirectory: String = NSHomeDirectory()) {
        self.fileChecker = fileChecker
        self.homeDirectory = homeDirectory
    }

    /// Returns all detected MCP clients.
    func detect() -> [MCPClient] {
        let knownClients: [(name: String, relativePath: String, bundleIdentifier: String?)] = [
            ("Claude Desktop", "Library/Application Support/Claude/claude_desktop_config.json", "com.anthropic.claudedesktop"),
            ("Claude Code", ".claude.json", nil),
        ]

        return knownClients.compactMap { client in
            let fullPath = "\(homeDirectory)/\(client.relativePath)"
            guard fileChecker.fileExists(atPath: fullPath) else { return nil }
            return MCPClient(
                name: client.name,
                configPath: fullPath,
                bundleIdentifier: client.bundleIdentifier
            )
        }
    }
}
