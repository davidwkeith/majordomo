import Testing
@testable import Majordomo

@Test func voiceInputStartsIdle() {
    let state = VoiceInputState()
    #expect(state.mode == .idle)
    #expect(state.transcript == "")
    #expect(state.error == nil)
}

@Test func voiceInputTransitionsToListening() {
    var state = VoiceInputState()
    state.startListening()
    #expect(state.mode == .listening)
    #expect(state.transcript == "")
}

@Test func voiceInputUpdatesTranscript() {
    var state = VoiceInputState()
    state.startListening()
    state.updateTranscript("Hello Majordomo")
    #expect(state.mode == .listening)
    #expect(state.transcript == "Hello Majordomo")
}

@Test func voiceInputTransitionsToProcessing() {
    var state = VoiceInputState()
    state.startListening()
    state.updateTranscript("Send an email")
    state.finishListening()
    #expect(state.mode == .processing)
    #expect(state.transcript == "Send an email")
}

@Test func voiceInputTransitionsToResponding() {
    var state = VoiceInputState()
    state.startListening()
    state.finishListening()
    state.startResponding(text: "Done!")
    #expect(state.mode == .responding)
    #expect(state.responseText == "Done!")
}

@Test func voiceInputTransitionsToError() {
    var state = VoiceInputState()
    state.startListening()
    state.fail(message: "Microphone unavailable")
    #expect(state.mode == .error)
    #expect(state.error == "Microphone unavailable")
}

@Test func voiceInputResetsToIdle() {
    var state = VoiceInputState()
    state.startListening()
    state.updateTranscript("Hello")
    state.finishListening()
    state.reset()
    #expect(state.mode == .idle)
    #expect(state.transcript == "")
    #expect(state.responseText == nil)
    #expect(state.error == nil)
}

@Test func voiceInputStopFromListeningGoesIdle() {
    var state = VoiceInputState()
    state.startListening()
    state.stopListening()
    #expect(state.mode == .idle)
    #expect(state.transcript == "")
}
