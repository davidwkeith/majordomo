import Foundation
import Testing
@testable import Majordomo

// MARK: - ScriptStore Tests

@Test func storeListsEmptyByDefault() throws {
    let io = MockScriptFileIO()
    let store = ScriptStore(fileIO: io)
    #expect(store.list().isEmpty)
}

@Test func storeCreatesAndListsScript() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(
        id: "s1",
        name: "Test",
        description: "A test script",
        steps: [ScriptStep(tool: "volume", parameters: ["level": .int(50)])]
    )
    try store.create(script)

    let scripts = store.list()
    #expect(scripts.count == 1)
    #expect(scripts[0].id == "s1")
    #expect(scripts[0].name == "Test")
}

@Test func storeGetsScriptByID() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(id: "s1", name: "Test", description: "desc", steps: [])
    try store.create(script)

    let found = store.get(id: "s1")
    #expect(found == script)
}

@Test func storeReturnsNilForUnknownID() {
    let io = MockScriptFileIO()
    let store = ScriptStore(fileIO: io)
    #expect(store.get(id: "nonexistent") == nil)
}

@Test func storeDeletesScript() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(id: "s1", name: "Test", description: "desc", steps: [])
    try store.create(script)
    try store.delete(id: "s1")

    #expect(store.list().isEmpty)
    #expect(store.get(id: "s1") == nil)
}

@Test func storeDeleteThrowsForUnknownID() {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    #expect(throws: ScriptStoreError.self) {
        try store.delete(id: "nonexistent")
    }
}

@Test func storeRejectsDuplicateID() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(id: "s1", name: "Test", description: "desc", steps: [])
    try store.create(script)

    #expect(throws: ScriptStoreError.self) {
        try store.create(script)
    }
}

@Test func storePersistsOnCreate() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(id: "s1", name: "Test", description: "desc", steps: [])
    try store.create(script)

    #expect(io.lastWrittenData != nil)
    let saved = try JSONDecoder().decode([Script].self, from: io.lastWrittenData!)
    #expect(saved.count == 1)
    #expect(saved[0].id == "s1")
}

@Test func storePersistsOnDelete() throws {
    let io = MockScriptFileIO()
    var store = ScriptStore(fileIO: io)

    let script = Script(id: "s1", name: "Test", description: "desc", steps: [])
    try store.create(script)
    try store.delete(id: "s1")

    let saved = try JSONDecoder().decode([Script].self, from: io.lastWrittenData!)
    #expect(saved.isEmpty)
}

@Test func storeLoadsFromExistingFile() throws {
    let io = MockScriptFileIO()
    let existing = [Script(id: "s1", name: "Existing", description: "Already saved", steps: [])]
    io.existingData = try JSONEncoder().encode(existing)

    let store = ScriptStore(fileIO: io)
    #expect(store.list().count == 1)
    #expect(store.list()[0].name == "Existing")
}

@Test func storeHandlesMissingFileGracefully() {
    let io = MockScriptFileIO()
    io.existingData = nil
    let store = ScriptStore(fileIO: io)
    #expect(store.list().isEmpty)
}

@Test func storeHandlesCorruptFileGracefully() {
    let io = MockScriptFileIO()
    io.existingData = "not json".data(using: .utf8)
    let store = ScriptStore(fileIO: io)
    #expect(store.list().isEmpty)
}
