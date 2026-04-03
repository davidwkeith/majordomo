import Testing
@testable import Majordomo

@Test func doubleTapDetectorFiresOnDoubleTap() {
    var activated = false
    let detector = DoubleTapDetector(maxInterval: 0.5) { activated = true }

    detector.recordTap(at: 0.0)
    #expect(activated == false)
    detector.recordTap(at: 0.3)
    #expect(activated == true)
}

@Test func doubleTapDetectorIgnoresSlowTaps() {
    var activated = false
    let detector = DoubleTapDetector(maxInterval: 0.5) { activated = true }

    detector.recordTap(at: 0.0)
    detector.recordTap(at: 0.8)
    #expect(activated == false)
}

@Test func doubleTapDetectorResetsAfterActivation() {
    var count = 0
    let detector = DoubleTapDetector(maxInterval: 0.5) { count += 1 }

    detector.recordTap(at: 0.0)
    detector.recordTap(at: 0.3)
    #expect(count == 1)

    // Next single tap should not activate
    detector.recordTap(at: 1.0)
    #expect(count == 1)

    // But another double tap should
    detector.recordTap(at: 1.3)
    #expect(count == 2)
}

@Test func doubleTapDetectorIgnoresTripleTap() {
    var count = 0
    let detector = DoubleTapDetector(maxInterval: 0.5) { count += 1 }

    detector.recordTap(at: 0.0)
    detector.recordTap(at: 0.2)
    #expect(count == 1)

    // Third tap immediately after should not re-fire (reset happened)
    detector.recordTap(at: 0.4)
    #expect(count == 1)
}

@Test func mockHotkeyMonitorDeliversActivations() async {
    let monitor = MockHotkeyMonitor()

    monitor.simulateActivation()
    monitor.simulateActivation()
    monitor.finish()

    var count = 0
    for await _ in monitor.activations {
        count += 1
    }
    #expect(count == 2)
}

@Test func mockHotkeyMonitorTracksRunning() {
    let monitor = MockHotkeyMonitor()
    #expect(monitor.isRunning == false)
    monitor.start()
    #expect(monitor.isRunning == true)
    monitor.stop()
    #expect(monitor.isRunning == false)
}
