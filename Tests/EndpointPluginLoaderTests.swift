import Foundation
import Testing
@testable import Majordomo

// MARK: - Mock Directory IO

final class MockDirectoryIO: DirectoryReadable {
    var directories: Set<String> = []
    var files: [String: Data] = [:]

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        let prefix = path.hasSuffix("/") ? path : path + "/"
        var entries: Set<String> = []
        for key in files.keys {
            if key.hasPrefix(prefix) {
                let remainder = String(key.dropFirst(prefix.count))
                if let slashIndex = remainder.firstIndex(of: "/") {
                    entries.insert(String(remainder[remainder.startIndex..<slashIndex]))
                } else {
                    entries.insert(remainder)
                }
            }
        }
        for dir in directories {
            if dir.hasPrefix(prefix) {
                let remainder = String(dir.dropFirst(prefix.count))
                if !remainder.contains("/") && !remainder.isEmpty {
                    entries.insert(remainder)
                }
            }
        }
        if entries.isEmpty && !directories.contains(path) {
            throw NSError(domain: "MockDirectoryIO", code: 1, userInfo: [NSLocalizedDescriptionKey: "Directory not found: \(path)"])
        }
        return entries.sorted()
    }

    func fileExists(atPath path: String) -> Bool {
        files[path] != nil
    }

    func readFile(atPath path: String) throws -> Data {
        guard let data = files[path] else {
            throw NSError(domain: "MockDirectoryIO", code: 2, userInfo: [NSLocalizedDescriptionKey: "File not found: \(path)"])
        }
        return data
    }
}

// MARK: - Tests

private func makeManifestJSON(
    name: String = "Test Plugin",
    id: String = "com.test.majordomo-plugin",
    endpointType: String = "https",
    baseURL: String = "https://example.com"
) -> Data {
    """
    {
      "name": "\(name)",
      "id": "\(id)",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "A test plugin.",
      "endpoint": {
        "type": "\(endpointType)",
        "base_url": "\(baseURL)"
      }
    }
    """.data(using: .utf8)!
}

@Test func loadsValidPluginBundle() throws {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/TestPlugin.majordomo-plugin"
    io.directories.insert(bundlePath)
    io.files[bundlePath + "/manifest.json"] = makeManifestJSON()

    let loader = EndpointPluginLoader(directoryIO: io)
    let plugin = try loader.loadPlugin(at: bundlePath)

    #expect(plugin.manifest.name == "Test Plugin")
    #expect(plugin.manifest.id == "com.test.majordomo-plugin")
    #expect(plugin.bundlePath == bundlePath)
}

@Test func throwsWhenManifestMissing() {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/NoManifest.majordomo-plugin"
    io.directories.insert(bundlePath)

    let loader = EndpointPluginLoader(directoryIO: io)

    #expect(throws: EndpointPluginError.self) {
        try loader.loadPlugin(at: bundlePath)
    }
}

@Test func throwsWhenManifestIsInvalidJSON() {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/BadJSON.majordomo-plugin"
    io.directories.insert(bundlePath)
    io.files[bundlePath + "/manifest.json"] = "not json".data(using: .utf8)!

    let loader = EndpointPluginLoader(directoryIO: io)

    #expect(throws: EndpointPluginError.self) {
        try loader.loadPlugin(at: bundlePath)
    }
}

@Test func throwsWhenTypeIsNotEndpoint() {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/WrongType.majordomo-plugin"
    io.directories.insert(bundlePath)
    io.files[bundlePath + "/manifest.json"] = """
    {
      "name": "Wrong",
      "id": "com.wrong.majordomo-plugin",
      "type": "not-endpoint",
      "version": "1.0.0",
      "description": "Wrong type.",
      "endpoint": { "type": "https", "base_url": "https://example.com" }
    }
    """.data(using: .utf8)!

    let loader = EndpointPluginLoader(directoryIO: io)

    #expect(throws: EndpointPluginError.self) {
        try loader.loadPlugin(at: bundlePath)
    }
}

@Test func loadedPluginIncludesGeneratedCapabilityTools() throws {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/TV.majordomo-plugin"
    io.directories.insert(bundlePath)
    io.files[bundlePath + "/manifest.json"] = """
    {
      "name": "TV",
      "id": "com.tv.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "A TV.",
      "endpoint": { "type": "lan-ws", "address": "lan://10.0.0.1:8001" },
      "tool_prefix": "tv",
      "capabilities": {
        "power": { "type": "boolean" },
        "volume": { "type": "integer", "min": 0, "max": 100 }
      }
    }
    """.data(using: .utf8)!

    let loader = EndpointPluginLoader(directoryIO: io)
    let plugin = try loader.loadPlugin(at: bundlePath)

    // power: get + set, volume: get + set = 4
    #expect(plugin.generatedTools.count == 4)

    let names = Set(plugin.generatedTools.map(\.name))
    #expect(names.contains("tv_get_power"))
    #expect(names.contains("tv_set_power"))
    #expect(names.contains("tv_get_volume"))
    #expect(names.contains("tv_set_volume"))
}

@Test func discoversPluginBundlesInDirectory() throws {
    let io = MockDirectoryIO()
    let pluginsDir = "/plugins"
    io.directories.insert(pluginsDir)

    let bundle1 = pluginsDir + "/PluginA.majordomo-plugin"
    let bundle2 = pluginsDir + "/PluginB.majordomo-plugin"
    io.directories.insert(bundle1)
    io.directories.insert(bundle2)
    io.files[bundle1 + "/manifest.json"] = makeManifestJSON(name: "Plugin A", id: "com.a")
    io.files[bundle2 + "/manifest.json"] = makeManifestJSON(name: "Plugin B", id: "com.b")

    // Also put a non-plugin directory in there
    io.directories.insert(pluginsDir + "/not-a-plugin")

    let loader = EndpointPluginLoader(directoryIO: io)
    let plugins = loader.discoverPlugins(in: pluginsDir)

    #expect(plugins.count == 2)
    let names = Set(plugins.map(\.manifest.name))
    #expect(names.contains("Plugin A"))
    #expect(names.contains("Plugin B"))
}

@Test func discoverySkipsInvalidBundles() throws {
    let io = MockDirectoryIO()
    let pluginsDir = "/plugins"
    io.directories.insert(pluginsDir)

    let good = pluginsDir + "/Good.majordomo-plugin"
    let bad = pluginsDir + "/Bad.majordomo-plugin"
    io.directories.insert(good)
    io.directories.insert(bad)
    io.files[good + "/manifest.json"] = makeManifestJSON(name: "Good")
    // bad has no manifest.json

    let loader = EndpointPluginLoader(directoryIO: io)
    let plugins = loader.discoverPlugins(in: pluginsDir)

    #expect(plugins.count == 1)
    #expect(plugins[0].manifest.name == "Good")
}

@Test func allToolsCombinesManifestAndGeneratedTools() throws {
    let io = MockDirectoryIO()
    let bundlePath = "/plugins/Full.majordomo-plugin"
    io.directories.insert(bundlePath)
    io.files[bundlePath + "/manifest.json"] = """
    {
      "name": "Full",
      "id": "com.full.majordomo-plugin",
      "type": "endpoint",
      "version": "1.0.0",
      "description": "Full plugin.",
      "endpoint": { "type": "lan-ws", "address": "lan://10.0.0.1:8001" },
      "tool_prefix": "device",
      "tools": [
        { "name": "device_custom_action", "description": "A custom action." }
      ],
      "capabilities": {
        "power": { "type": "boolean" }
      }
    }
    """.data(using: .utf8)!

    let loader = EndpointPluginLoader(directoryIO: io)
    let plugin = try loader.loadPlugin(at: bundlePath)

    // 1 manifest tool + 2 generated (get_power, set_power)
    #expect(plugin.allTools.count == 3)

    let names = Set(plugin.allTools.map(\.name))
    #expect(names.contains("device_custom_action"))
    #expect(names.contains("device_get_power"))
    #expect(names.contains("device_set_power"))
}
