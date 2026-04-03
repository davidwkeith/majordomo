import Testing
@testable import Majordomo

@Test @MainActor func sessionManagerStartsIdle() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)
    #expect(manager.state.mode == .idle)
}

@Test @MainActor func startSessionTransitionsToListening() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    #expect(manager.state.mode == .listening)
    #expect(recognizer.isListening == true)
}

@Test @MainActor func stopSessionTransitionsToIdle() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    manager.stopSession()
    #expect(manager.state.mode == .idle)
    #expect(recognizer.isListening == false)
}

@Test @MainActor func finishSessionTransitionsToProcessing() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    manager.state.updateTranscript("Do something")
    manager.finishSession()
    #expect(manager.state.mode == .processing)
    #expect(recognizer.isListening == false)
}

@Test @MainActor func deliverResponseTransitionsToResponding() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    manager.finishSession()
    manager.deliverResponse(text: "Here you go")
    #expect(manager.state.mode == .responding)
    #expect(manager.state.responseText == "Here you go")
}

@Test @MainActor func completeResponseResetsToIdle() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    manager.finishSession()
    manager.deliverResponse(text: "Done")
    manager.completeResponse()
    #expect(manager.state.mode == .idle)
}

@Test @MainActor func toggleSessionStartsWhenIdle() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.toggleSession()
    #expect(manager.state.mode == .listening)
}

@Test @MainActor func toggleSessionStopsWhenListening() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startSession()
    manager.toggleSession()
    #expect(manager.state.mode == .idle)
}

@Test @MainActor func sessionManagerStartsHotkeyMonitor() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startMonitoring()
    #expect(hotkey.isRunning == true)
}

@Test @MainActor func sessionManagerStopsHotkeyMonitor() {
    let recognizer = MockSpeechRecognizer()
    let hotkey = MockHotkeyMonitor()
    let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkey)

    manager.startMonitoring()
    manager.stopMonitoring()
    #expect(hotkey.isRunning == false)
}
