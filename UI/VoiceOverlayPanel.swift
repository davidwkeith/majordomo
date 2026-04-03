import AppKit
import SwiftUI

/// Floating NSPanel that hosts the VoiceOverlayView.
/// Non-activating: does not steal focus from the frontmost app.
/// Positioned top-right of the main screen.
final class VoiceOverlayPanel: NSPanel {
    private var hostingView: NSHostingView<VoiceOverlayView>?

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 56),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: true
        )
        isFloatingPanel = true
        level = .floating
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        isMovableByWindowBackground = true
        titlebarAppearsTransparent = true
        titleVisibility = .hidden

        positionTopRight()
    }

    func update(state: VoiceInputState) {
        let overlay = VoiceOverlayView(state: state)

        if let existing = hostingView {
            existing.rootView = overlay
        } else {
            let hosting = NSHostingView(rootView: overlay)
            hostingView = hosting
            contentView = hosting
        }

        if state.mode == .idle {
            orderOut(nil)
        } else {
            orderFrontRegardless()
        }
    }

    private func positionTopRight() {
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.visibleFrame
        let panelFrame = frame
        let x = screenFrame.maxX - panelFrame.width - 16
        let y = screenFrame.maxY - panelFrame.height - 16
        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
