import Foundation
import Speech

/// Errors that can occur during speech recognition.
enum SpeechRecognitionError: Error, Equatable {
    case notAvailable
    case notAuthorized
    case recognitionFailed(String)
}

/// Protocol for speech recognition, enabling dependency injection and testing.
protocol SpeechRecognizing: AnyObject {
    var isListening: Bool { get }
    var transcripts: AsyncStream<String> { get }
    var lastError: (any Error)? { get }
    func start()
    func stop()
}

/// Mock implementation for testing.
final class MockSpeechRecognizer: SpeechRecognizing {
    var transcriptsToEmit: [String] = []
    var errorToEmit: SpeechRecognitionError?
    private(set) var isListening = false
    private(set) var lastError: (any Error)?

    private var continuation: AsyncStream<String>.Continuation?
    private var _transcripts: AsyncStream<String>?

    var transcripts: AsyncStream<String> {
        if let existing = _transcripts { return existing }
        let stream = AsyncStream<String> { continuation in
            self.continuation = continuation
        }
        _transcripts = stream
        return stream
    }

    func start() {
        isListening = true
        // Reset stream for new session
        _transcripts = nil
        let transcripts = transcriptsToEmit
        let error = errorToEmit
        let stream = AsyncStream<String> { [weak self] continuation in
            guard let self else { return }
            self.continuation = continuation
            if let error {
                self.lastError = error
                self.isListening = false
                continuation.finish()
            } else if !transcripts.isEmpty {
                for transcript in transcripts {
                    continuation.yield(transcript)
                }
                self.isListening = false
                continuation.finish()
            }
            // If no transcripts and no error, stream stays open until stop() is called
        }
        _transcripts = stream
    }

    func stop() {
        isListening = false
        continuation?.finish()
        continuation = nil
    }
}

/// On-device speech recognizer using SFSpeechRecognizer. No audio leaves the Mac.
final class OnDeviceSpeechRecognizer: SpeechRecognizing {
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncStream<String>.Continuation?

    private(set) var isListening = false
    private(set) var lastError: (any Error)?
    private var _transcripts: AsyncStream<String>?

    var transcripts: AsyncStream<String> {
        if let existing = _transcripts { return existing }
        let stream = AsyncStream<String> { continuation in
            self.continuation = continuation
        }
        _transcripts = stream
        return stream
    }

    init(locale: Locale = .current) {
        self.speechRecognizer = SFSpeechRecognizer(locale: locale)
    }

    func start() {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            lastError = SpeechRecognitionError.notAvailable
            return
        }

        _transcripts = nil
        let stream = AsyncStream<String> { [weak self] continuation in
            self?.continuation = continuation
            self?.beginRecognition(continuation: continuation)
        }
        _transcripts = stream
        isListening = true
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
        continuation?.finish()
        continuation = nil
    }

    private func beginRecognition(continuation: AsyncStream<String>.Continuation) {
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        self.recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            lastError = SpeechRecognitionError.recognitionFailed(error.localizedDescription)
            continuation.finish()
            return
        }

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            if let result {
                continuation.yield(result.bestTranscription.formattedString)
            }
            if let error {
                self?.lastError = SpeechRecognitionError.recognitionFailed(error.localizedDescription)
                self?.stop()
            }
            if result?.isFinal == true {
                self?.stop()
            }
        }
    }
}
