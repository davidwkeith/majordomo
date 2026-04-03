import SwiftUI

/// Floating voice overlay showing waveform and transcript.
/// Positioned top-right of the screen, auto-dismisses after response.
struct VoiceOverlayView: View {
    let state: VoiceInputState

    var body: some View {
        HStack(spacing: 12) {
            microphoneIcon
            waveformView
            statusText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
    }

    private var microphoneIcon: some View {
        Image(systemName: state.mode == .error ? "mic.slash.fill" : "mic.fill")
            .font(.title2)
            .foregroundStyle(iconColor)
            .symbolEffect(.pulse, isActive: state.mode == .listening)
    }

    private var waveformView: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { index in
                WaveformBar(isActive: state.mode == .listening, index: index)
            }
        }
        .frame(width: 40, height: 20)
    }

    private var statusText: some View {
        Group {
            switch state.mode {
            case .idle:
                EmptyView()
            case .listening:
                Text(state.transcript.isEmpty ? "Listening..." : state.transcript)
            case .processing:
                Text("Processing...")
            case .responding:
                Text(state.responseText ?? "")
            case .error:
                Text(state.error ?? "Error")
            }
        }
        .font(.callout)
        .lineLimit(1)
        .truncationMode(.tail)
        .frame(maxWidth: 200, alignment: .leading)
    }

    private var iconColor: Color {
        switch state.mode {
        case .idle: .secondary
        case .listening: .red
        case .processing: .orange
        case .responding: .blue
        case .error: .red
        }
    }
}

/// Individual waveform bar that animates when voice is active.
struct WaveformBar: View {
    let isActive: Bool
    let index: Int

    @State private var height: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(isActive ? Color.red : Color.secondary.opacity(0.3))
            .frame(width: 4, height: height)
            .onChange(of: isActive) { _, active in
                if active {
                    startAnimating()
                } else {
                    withAnimation(.easeOut(duration: 0.2)) {
                        height = 4
                    }
                }
            }
    }

    private func startAnimating() {
        let delay = Double(index) * 0.1
        withAnimation(
            .easeInOut(duration: 0.4)
            .repeatForever(autoreverses: true)
            .delay(delay)
        ) {
            height = CGFloat.random(in: 8...20)
        }
    }
}
