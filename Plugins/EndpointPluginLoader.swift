import Foundation

/// Protocol for directory and file access (injectable for testing).
protocol DirectoryReadable {
    func contentsOfDirectory(atPath path: String) throws -> [String]
    func fileExists(atPath path: String) -> Bool
    func readFile(atPath path: String) throws -> Data
}

/// Default implementation using FileManager.
struct DefaultDirectoryIO: DirectoryReadable {
    private let fileManager = FileManager.default

    func contentsOfDirectory(atPath path: String) throws -> [String] {
        try fileManager.contentsOfDirectory(atPath: path)
    }

    func fileExists(atPath path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func readFile(atPath path: String) throws -> Data {
        try Data(contentsOf: URL(fileURLWithPath: path))
    }
}

/// Errors during plugin loading.
enum EndpointPluginError: Error {
    case manifestNotFound(String)
    case invalidManifest(String, Error)
    case invalidType(String, String)
}

/// A loaded endpoint plugin with its parsed manifest and generated tools.
struct LoadedEndpointPlugin: Sendable {
    let bundlePath: String
    let manifest: EndpointManifest
    let generatedTools: [ToolDefinition]

    /// All tools: manifest-declared tools + auto-generated capability tools.
    var allTools: [ToolDefinition] {
        (manifest.tools ?? []) + generatedTools
    }
}

/// Loads `.majordomo-plugin` bundles from disk.
struct EndpointPluginLoader {
    private let directoryIO: DirectoryReadable

    init(directoryIO: DirectoryReadable = DefaultDirectoryIO()) {
        self.directoryIO = directoryIO
    }

    /// Load a single plugin bundle at the given path.
    func loadPlugin(at bundlePath: String) throws -> LoadedEndpointPlugin {
        let manifestPath = bundlePath + "/manifest.json"

        guard directoryIO.fileExists(atPath: manifestPath) else {
            throw EndpointPluginError.manifestNotFound(bundlePath)
        }

        let data: Data
        do {
            data = try directoryIO.readFile(atPath: manifestPath)
        } catch {
            throw EndpointPluginError.manifestNotFound(bundlePath)
        }

        let manifest: EndpointManifest
        do {
            manifest = try JSONDecoder().decode(EndpointManifest.self, from: data)
        } catch {
            throw EndpointPluginError.invalidManifest(bundlePath, error)
        }

        guard manifest.type == "endpoint" else {
            throw EndpointPluginError.invalidType(bundlePath, manifest.type)
        }

        let generatedTools = CapabilityToolGenerator.generateAllTools(from: manifest)

        return LoadedEndpointPlugin(
            bundlePath: bundlePath,
            manifest: manifest,
            generatedTools: generatedTools
        )
    }

    /// Discover and load all `.majordomo-plugin` bundles in a directory.
    /// Invalid bundles are silently skipped.
    func discoverPlugins(in directoryPath: String) -> [LoadedEndpointPlugin] {
        guard let entries = try? directoryIO.contentsOfDirectory(atPath: directoryPath) else {
            return []
        }

        return entries.compactMap { entry in
            guard entry.hasSuffix(".majordomo-plugin") else { return nil }
            let bundlePath = directoryPath + "/" + entry
            return try? loadPlugin(at: bundlePath)
        }
    }
}
