import Testing
@testable import Majordomo

@Test func mockRecognizerDeliversTranscripts() async {
    let recognizer = MockSpeechRecognizer()
    recognizer.transcriptsToEmit = ["Hello", "Hello world"]

    var results: [String] = []
    recognizer.start()
    for await transcript in recognizer.transcripts {
        results.append(transcript)
    }
    #expect(results == ["Hello", "Hello world"])
}

@Test func mockRecognizerStopEndsStream() async {
    let recognizer = MockSpeechRecognizer()
    recognizer.transcriptsToEmit = ["Hi"]

    recognizer.start()
    var count = 0
    for await _ in recognizer.transcripts {
        count += 1
    }
    #expect(count == 1)
    #expect(recognizer.isListening == false)
}

@Test func mockRecognizerReportsListeningState() {
    let recognizer = MockSpeechRecognizer()
    #expect(recognizer.isListening == false)
    recognizer.start()
    #expect(recognizer.isListening == true)
    recognizer.stop()
    #expect(recognizer.isListening == false)
}

@Test func mockRecognizerCanEmitError() async {
    let recognizer = MockSpeechRecognizer()
    recognizer.errorToEmit = SpeechRecognitionError.notAuthorized

    recognizer.start()
    var results: [String] = []
    for await transcript in recognizer.transcripts {
        results.append(transcript)
    }
    #expect(results.isEmpty)
    #expect(recognizer.lastError as? SpeechRecognitionError == .notAuthorized)
}
