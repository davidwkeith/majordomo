import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var voiceSessionManager: VoiceSessionManager?
    private var voiceOverlayPanel: VoiceOverlayPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Start server, register tools

        setupVoice()
    }

    private func setupVoice() {
        let recognizer = OnDeviceSpeechRecognizer()
        let hotkeyMonitor = GlobalFnHotkeyMonitor()
        let manager = VoiceSessionManager(recognizer: recognizer, hotkeyMonitor: hotkeyMonitor)
        voiceSessionManager = manager

        let panel = VoiceOverlayPanel()
        voiceOverlayPanel = panel

        manager.startMonitoring()
    }
}
