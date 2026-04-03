import Foundation
import Testing
@testable import Majordomo

final class MockFileIO: FileReadWrite {
    var files: [String: Data] = [:]

    func read(from path: String) throws -> Data {
        guard let data = files[path] else {
            throw NSError(domain: "MockFileIO", code: 1, userInfo: [NSLocalizedDescriptionKey: "File not found: \(path)"])
        }
        return data
    }

    func write(_ data: Data, to path: String) throws {
        files[path] = data
    }
}

@Test func patchThrowsWhenConfigFileDoesNotExist() {
    let fileIO = MockFileIO()
    let patcher = MCPClientPatcher(fileIO: fileIO)

    #expect(throws: (any Error).self) {
        try patcher.patch(configPath: "/nonexistent/config.json")
    }
}

@Test func patchAddsEntryToExistingMcpServers() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = [
        "mcpServers": [
            "some-server": ["command": "node", "args": ["server.js"]]
        ]
    ]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(fileIO: fileIO)
    let modified = try patcher.patch(configPath: "/config.json")

    #expect(modified == true)

    let writtenData = fileIO.files["/config.json"]!
    let result = try JSONSerialization.jsonObject(with: writtenData) as! [String: Any]
    let servers = result["mcpServers"] as! [String: Any]

    #expect(servers.count == 2)
    #expect(servers["some-server"] != nil)
    let majordomo = servers["majordomo"] as! [String: Any]
    #expect(majordomo["url"] as! String == "http://localhost:3742/mcp")
}

@Test func patchCreatesMcpServersWhenKeyMissing() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = ["someOtherKey": "value"]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(fileIO: fileIO)
    let modified = try patcher.patch(configPath: "/config.json")

    #expect(modified == true)

    let writtenData = fileIO.files["/config.json"]!
    let result = try JSONSerialization.jsonObject(with: writtenData) as! [String: Any]
    let servers = result["mcpServers"] as! [String: Any]
    let majordomo = servers["majordomo"] as! [String: Any]

    #expect(majordomo["url"] as! String == "http://localhost:3742/mcp")
    #expect(result["someOtherKey"] as! String == "value")
}

@Test func patchReturnsFalseWhenAlreadyCorrect() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = [
        "mcpServers": [
            "majordomo": ["url": "http://localhost:3742/mcp"]
        ]
    ]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(fileIO: fileIO)
    let modified = try patcher.patch(configPath: "/config.json")

    #expect(modified == false)
}

@Test func patchUpdatesMajordomoWhenURLDiffers() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = [
        "mcpServers": [
            "majordomo": ["url": "http://localhost:9999/mcp"]
        ]
    ]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(fileIO: fileIO)
    let modified = try patcher.patch(configPath: "/config.json")

    #expect(modified == true)

    let writtenData = fileIO.files["/config.json"]!
    let result = try JSONSerialization.jsonObject(with: writtenData) as! [String: Any]
    let servers = result["mcpServers"] as! [String: Any]
    let majordomo = servers["majordomo"] as! [String: Any]
    #expect(majordomo["url"] as! String == "http://localhost:3742/mcp")
}

@Test func patchWritesPrettyPrintedJSON() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = [
        "mcpServers": [:]
    ]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(fileIO: fileIO)
    _ = try patcher.patch(configPath: "/config.json")

    let writtenData = fileIO.files["/config.json"]!
    let jsonString = String(data: writtenData, encoding: .utf8)!

    // Pretty-printed JSON has newlines and indentation
    #expect(jsonString.contains("\n"))
    #expect(jsonString.contains("  "))
}

@Test func patchUsesCustomPort() throws {
    let fileIO = MockFileIO()
    let existingConfig: [String: Any] = ["mcpServers": [:]]
    let configData = try JSONSerialization.data(withJSONObject: existingConfig)
    fileIO.files["/config.json"] = configData

    let patcher = MCPClientPatcher(port: 8080, fileIO: fileIO)
    let modified = try patcher.patch(configPath: "/config.json")

    #expect(modified == true)

    let writtenData = fileIO.files["/config.json"]!
    let result = try JSONSerialization.jsonObject(with: writtenData) as! [String: Any]
    let servers = result["mcpServers"] as! [String: Any]
    let majordomo = servers["majordomo"] as! [String: Any]
    #expect(majordomo["url"] as! String == "http://localhost:8080/mcp")
}
