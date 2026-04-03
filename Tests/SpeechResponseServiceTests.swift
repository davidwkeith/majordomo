import Testing
@testable import Majordomo

@Test func mockSynthesizerSpeaksText() {
    let synth = MockSpeechSynthesizer()
    synth.speak("Hello world")
    #expect(synth.spokenTexts == ["Hello world"])
    #expect(synth.isSpeaking == true)
}

@Test func mockSynthesizerStops() {
    let synth = MockSpeechSynthesizer()
    synth.speak("Hello")
    synth.stopSpeaking()
    #expect(synth.isSpeaking == false)
}

@Test func mockSynthesizerTracksMultipleUtterances() {
    let synth = MockSpeechSynthesizer()
    synth.speak("First")
    synth.finishSpeaking()
    synth.speak("Second")
    #expect(synth.spokenTexts == ["First", "Second"])
}

@Test func speechSettingsHaveDefaults() {
    let settings = SpeechResponseSettings()
    #expect(settings.isEnabled == true)
    #expect(settings.speakingRate == 0.5)
    #expect(settings.stopOnInput == true)
}

@Test func speechSettingsCustomizable() {
    var settings = SpeechResponseSettings()
    settings.isEnabled = false
    settings.speakingRate = 0.8
    settings.stopOnInput = false
    #expect(settings.isEnabled == false)
    #expect(settings.speakingRate == 0.8)
    #expect(settings.stopOnInput == false)
}
