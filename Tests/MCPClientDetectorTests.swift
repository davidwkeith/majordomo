import Foundation
import Testing
@testable import Majordomo

struct MockFileChecker: FileExistence {
    var existingPaths: Set<String> = []

    func fileExists(atPath path: String) -> Bool {
        existingPaths.contains(path)
    }
}

@Test func detectsClaudeDesktopWhenConfigExists() {
    let home = NSHomeDirectory()
    let configPath = "\(home)/Library/Application Support/Claude/claude_desktop_config.json"
    let checker = MockFileChecker(existingPaths: [configPath])
    let detector = MCPClientDetector(fileChecker: checker)

    let clients = detector.detect()

    #expect(clients.count == 1)
    #expect(clients.first?.name == "Claude Desktop")
    #expect(clients.first?.configPath == configPath)
    #expect(clients.first?.bundleIdentifier == "com.anthropic.claudedesktop")
}

@Test func detectsClaudeCodeWhenConfigExists() {
    let home = NSHomeDirectory()
    let configPath = "\(home)/.claude.json"
    let checker = MockFileChecker(existingPaths: [configPath])
    let detector = MCPClientDetector(fileChecker: checker)

    let clients = detector.detect()

    #expect(clients.count == 1)
    #expect(clients.first?.name == "Claude Code")
    #expect(clients.first?.configPath == configPath)
    #expect(clients.first?.bundleIdentifier == nil)
}

@Test func detectsBothClientsWhenBothExist() {
    let home = NSHomeDirectory()
    let desktopPath = "\(home)/Library/Application Support/Claude/claude_desktop_config.json"
    let codePath = "\(home)/.claude.json"
    let checker = MockFileChecker(existingPaths: [desktopPath, codePath])
    let detector = MCPClientDetector(fileChecker: checker)

    let clients = detector.detect()

    #expect(clients.count == 2)
    let names = clients.map(\MCPClient.name)
    #expect(names.contains("Claude Desktop"))
    #expect(names.contains("Claude Code"))
}

@Test func returnsEmptyArrayWhenNoClientsExist() {
    let checker = MockFileChecker(existingPaths: [])
    let detector = MCPClientDetector(fileChecker: checker)

    let clients = detector.detect()

    #expect(clients.isEmpty)
}

@Test func pathsUseCorrectHomeDirectory() {
    let home = NSHomeDirectory()
    let checker = MockFileChecker(existingPaths: [
        "\(home)/Library/Application Support/Claude/claude_desktop_config.json",
        "\(home)/.claude.json",
    ])
    let detector = MCPClientDetector(fileChecker: checker)

    let clients = detector.detect()

    for client in clients {
        #expect(client.configPath.hasPrefix(home))
    }
}
