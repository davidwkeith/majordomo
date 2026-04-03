import AVFoundation

/// Settings for spoken responses per TRD Section 16.5.
struct SpeechResponseSettings {
    var isEnabled: Bool = true
    var speakingRate: Float = 0.5
    var stopOnInput: Bool = true
}

/// Protocol for text-to-speech, enabling dependency injection and testing.
protocol SpeechSynthesizing: AnyObject {
    var isSpeaking: Bool { get }
    func speak(_ text: String)
    func stopSpeaking()
}

/// Mock implementation for testing.
final class MockSpeechSynthesizer: SpeechSynthesizing {
    private(set) var spokenTexts: [String] = []
    private(set) var isSpeaking = false

    func speak(_ text: String) {
        spokenTexts.append(text)
        isSpeaking = true
    }

    func stopSpeaking() {
        isSpeaking = false
    }

    func finishSpeaking() {
        isSpeaking = false
    }
}

/// System speech synthesizer using AVSpeechSynthesizer.
final class SystemSpeechSynthesizer: NSObject, SpeechSynthesizing, AVSpeechSynthesizerDelegate {
    private let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false
    var settings = SpeechResponseSettings()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        guard settings.isEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = settings.speakingRate
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }
}
