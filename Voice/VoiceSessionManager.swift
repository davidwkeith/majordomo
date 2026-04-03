import Foundation

/// Orchestrates voice input sessions by wiring hotkey activation to speech recognition.
@MainActor
final class VoiceSessionManager {
    var state = VoiceInputState()
    private let recognizer: any SpeechRecognizing
    private let hotkeyMonitor: any GlobalHotkeyMonitoring
    private var transcriptTask: Task<Void, Never>?

    init(recognizer: any SpeechRecognizing, hotkeyMonitor: any GlobalHotkeyMonitoring) {
        self.recognizer = recognizer
        self.hotkeyMonitor = hotkeyMonitor
    }

    func startSession() {
        state.startListening()
        recognizer.start()
        transcriptTask = Task { [weak self] in
            guard let self else { return }
            for await transcript in self.recognizer.transcripts {
                self.state.updateTranscript(transcript)
            }
        }
    }

    func stopSession() {
        transcriptTask?.cancel()
        transcriptTask = nil
        recognizer.stop()
        state.stopListening()
    }

    func finishSession() {
        transcriptTask?.cancel()
        transcriptTask = nil
        recognizer.stop()
        state.finishListening()
    }

    func deliverResponse(text: String) {
        state.startResponding(text: text)
    }

    func completeResponse() {
        state.reset()
    }

    func toggleSession() {
        switch state.mode {
        case .idle:
            startSession()
        case .listening:
            stopSession()
        default:
            break
        }
    }

    func startMonitoring() {
        hotkeyMonitor.start()
        Task { [weak self] in
            guard let self else { return }
            for await _ in self.hotkeyMonitor.activations {
                self.toggleSession()
            }
        }
    }

    func stopMonitoring() {
        hotkeyMonitor.stop()
    }
}
