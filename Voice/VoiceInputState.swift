import Foundation

/// Transient state for an active voice input session.
struct VoiceInputState {
    enum Mode: Equatable {
        case idle
        case listening
        case processing
        case responding
        case error
    }

    private(set) var mode: Mode = .idle
    private(set) var transcript: String = ""
    private(set) var responseText: String?
    private(set) var error: String?

    mutating func startListening() {
        mode = .listening
        transcript = ""
        responseText = nil
        error = nil
    }

    mutating func updateTranscript(_ text: String) {
        transcript = text
    }

    mutating func finishListening() {
        mode = .processing
    }

    mutating func stopListening() {
        mode = .idle
        transcript = ""
    }

    mutating func startResponding(text: String) {
        mode = .responding
        responseText = text
    }

    mutating func fail(message: String) {
        mode = .error
        error = message
    }

    mutating func reset() {
        mode = .idle
        transcript = ""
        responseText = nil
        error = nil
    }
}
