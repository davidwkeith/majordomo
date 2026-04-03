import SwiftUI
import AppKit

struct OnboardingFlowView: View {
    let onComplete: () -> Void

    @State private var currentStep = 0
    @State private var detectedClients: [MCPClient] = []
    @State private var connectedClient: MCPClient?

    var body: some View {
        Group {
            switch currentStep {
            case 0:
                OnboardingWelcomeView {
                    currentStep = 1
                }
            case 1:
                OnboardingConnectView(
                    detectedClients: detectedClients,
                    onPatch: { client in
                        patchClient(client)
                    },
                    onContinue: {
                        currentStep = 2
                    }
                )
            case 2:
                OnboardingTryItView(
                    connectedClientName: connectedClient?.name,
                    onOpenClient: {
                        openConnectedClient()
                        onComplete()
                    },
                    onSkip: {
                        onComplete()
                    }
                )
            default:
                EmptyView()
            }
        }
        .frame(width: 640)
        .onAppear {
            let detector = MCPClientDetector()
            detectedClients = detector.detect()
        }
    }

    private func patchClient(_ client: MCPClient) {
        let patcher = MCPClientPatcher()
        do {
            try patcher.patch(configPath: client.configPath)
            connectedClient = client
        } catch {
            // Patching failed; user can still proceed via manual setup
        }
    }

    private func openConnectedClient() {
        guard let bundleID = connectedClient?.bundleIdentifier,
              let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}
