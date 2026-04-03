import Foundation

/// Errors from script store operations.
enum ScriptStoreError: Error, Equatable {
    case duplicateID(String)
    case notFound(String)
}

/// Protocol for file I/O operations on the scripts storage file.
protocol ScriptFileIO: AnyObject {
    func read() -> Data?
    func write(_ data: Data) throws
}

/// Default implementation that reads/writes `scripts.json` in the app support directory.
final class DefaultScriptFileIO: ScriptFileIO {
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("app.majordomo", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("scripts.json")
    }

    func read() -> Data? {
        try? Data(contentsOf: fileURL)
    }

    func write(_ data: Data) throws {
        try data.write(to: fileURL, options: .atomic)
    }
}

/// Mock file I/O for testing.
final class MockScriptFileIO: ScriptFileIO {
    var existingData: Data?
    var lastWrittenData: Data?

    func read() -> Data? {
        existingData
    }

    func write(_ data: Data) throws {
        lastWrittenData = data
        existingData = data
    }
}

/// Manages saved scripts with CRUD operations and file persistence.
struct ScriptStore {
    private var scripts: [Script]
    private let fileIO: ScriptFileIO

    init(fileIO: ScriptFileIO) {
        self.fileIO = fileIO
        if let data = fileIO.read(),
           let loaded = try? JSONDecoder().decode([Script].self, from: data) {
            self.scripts = loaded
        } else {
            self.scripts = []
        }
    }

    /// List all saved scripts.
    func list() -> [Script] {
        scripts
    }

    /// Get a script by its ID.
    func get(id: String) -> Script? {
        scripts.first { $0.id == id }
    }

    /// Create a new script. Throws if the ID already exists.
    mutating func create(_ script: Script) throws {
        guard !scripts.contains(where: { $0.id == script.id }) else {
            throw ScriptStoreError.duplicateID(script.id)
        }
        scripts.append(script)
        try persist()
    }

    /// Delete a script by ID. Throws if not found.
    mutating func delete(id: String) throws {
        guard scripts.contains(where: { $0.id == id }) else {
            throw ScriptStoreError.notFound(id)
        }
        scripts.removeAll { $0.id == id }
        try persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(scripts)
        try fileIO.write(data)
    }
}
