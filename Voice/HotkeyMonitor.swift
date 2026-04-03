import AppKit

/// Detects double-tap of a key within a time interval. Pure logic, no framework dependency.
final class DoubleTapDetector {
    private let maxInterval: TimeInterval
    private let onActivation: () -> Void
    private var lastTapTime: TimeInterval?

    init(maxInterval: TimeInterval = 0.4, onActivation: @escaping () -> Void) {
        self.maxInterval = maxInterval
        self.onActivation = onActivation
    }

    func recordTap(at time: TimeInterval) {
        if let last = lastTapTime, (time - last) <= maxInterval {
            onActivation()
            lastTapTime = nil // reset after activation
        } else {
            lastTapTime = time
        }
    }
}

/// Protocol for global hotkey monitoring, enabling dependency injection and testing.
protocol GlobalHotkeyMonitoring: AnyObject {
    var isRunning: Bool { get }
    var activations: AsyncStream<Void> { get }
    func start()
    func stop()
}

/// Mock implementation for testing.
final class MockHotkeyMonitor: GlobalHotkeyMonitoring {
    private(set) var isRunning = false
    private var continuation: AsyncStream<Void>.Continuation?
    private var _activations: AsyncStream<Void>?

    var activations: AsyncStream<Void> {
        if let existing = _activations { return existing }
        let stream = AsyncStream<Void> { continuation in
            self.continuation = continuation
        }
        _activations = stream
        return stream
    }

    func start() {
        isRunning = true
    }

    func stop() {
        isRunning = false
        continuation?.finish()
        continuation = nil
    }

    func simulateActivation() {
        if _activations == nil { _ = activations }
        continuation?.yield(())
    }

    func finish() {
        continuation?.finish()
    }
}

/// Monitors for double-Fn press globally using NSEvent.addGlobalMonitorForEvents.
/// Does NOT use CGEventTap — intentional security decision per TRD Section 16.
final class GlobalFnHotkeyMonitor: GlobalHotkeyMonitoring {
    private(set) var isRunning = false
    private var eventMonitor: Any?
    private var continuation: AsyncStream<Void>.Continuation?
    private var _activations: AsyncStream<Void>?
    private var detector: DoubleTapDetector?

    var activations: AsyncStream<Void> {
        if let existing = _activations { return existing }
        let stream = AsyncStream<Void> { continuation in
            self.continuation = continuation
        }
        _activations = stream
        return stream
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true

        if _activations == nil { _ = activations }

        detector = DoubleTapDetector { [weak self] in
            self?.continuation?.yield(())
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            // Detect Fn key press (flagsChanged with function key modifier)
            if event.modifierFlags.contains(.function) {
                self?.detector?.recordTap(at: event.timestamp)
            }
        }
    }

    func stop() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        detector = nil
        isRunning = false
        continuation?.finish()
        continuation = nil
    }
}
