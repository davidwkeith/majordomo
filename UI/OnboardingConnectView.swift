import SwiftUI
import AppKit

struct OnboardingConnectView: View {
    let detectedClients: [MCPClient]
    let onPatch: (MCPClient) -> Void
    let onContinue: () -> Void

    private let mcpURL = "http://localhost:3742/mcp"

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Connect your AI")
                .font(.title)
                .fontWeight(.bold)

            if !detectedClients.isEmpty {
                ForEach(detectedClients, id: \.name) { client in
                    VStack(alignment: .leading, spacing: 8) {
                        Label("\(client.name) found", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)

                        Text("Majordomo will add itself automatically.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Connect \(client.name)") {
                            onPatch(client)
                            onContinue()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("or connect manually")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Copy this address into your MCP client:")
                    .font(.body)

                HStack {
                    Text(mcpURL)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)

                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(mcpURL, forType: .string)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(40)
        .frame(width: 640, alignment: .leading)
    }
}
