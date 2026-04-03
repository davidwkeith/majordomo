import Foundation

/// Protocol for file I/O (injectable for testing).
protocol FileReadWrite {
    func read(from path: String) throws -> Data
    func write(_ data: Data, to path: String) throws
}

/// Default file I/O implementation using FileManager.
struct DefaultFileIO: FileReadWrite {
    func read(from path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }

    func write(_ data: Data, to path: String) throws {
        try data.write(to: URL(fileURLWithPath: path))
    }
}

/// Patches MCP client config files to include the Majordomo server entry.
struct MCPClientPatcher {
    private let fileIO: FileReadWrite
    private let port: Int

    init(port: Int = 3742, fileIO: FileReadWrite = DefaultFileIO()) {
        self.fileIO = fileIO
        self.port = port
    }

    /// Patches the config file to include the Majordomo server entry.
    /// Returns true if the config was modified (new entry or URL changed).
    @discardableResult
    func patch(configPath: String) throws -> Bool {
        let data = try fileIO.read(from: configPath)
        guard var config = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw NSError(
                domain: "MCPClientPatcher",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON in config file"]
            )
        }

        let expectedURL = "http://localhost:\(port)/mcp"
        let expectedEntry: [String: Any] = ["url": expectedURL]

        var servers = config["mcpServers"] as? [String: Any] ?? [:]

        // Check if already correct
        if let existing = servers["majordomo"] as? [String: Any],
           let existingURL = existing["url"] as? String,
           existingURL == expectedURL {
            return false
        }

        servers["majordomo"] = expectedEntry
        config["mcpServers"] = servers

        let writtenData = try JSONSerialization.data(
            withJSONObject: config,
            options: [.prettyPrinted, .sortedKeys]
        )
        try fileIO.write(writtenData, to: configPath)

        return true
    }
}
