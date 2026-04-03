import SwiftUI

struct OnboardingTryItView: View {
    let connectedClientName: String?
    let onOpenClient: () -> Void
    let onSkip: () -> Void

    private var promptText: String {
        if let name = connectedClientName {
            return "\(name) is connected. Try asking:"
        }
        return "Your AI is ready. Try asking:"
    }

    private var openButtonTitle: String {
        if let name = connectedClientName {
            return "Open \(name)"
        }
        return "Open Claude Desktop"
    }

    private let examplePrompts = [
        "What's on my calendar tomorrow?",
        "Close all my windows",
        "Remind me to call the dentist",
    ]

    var body: some View {
        VStack(spacing: 20) {
            Text("Ask Claude something")
                .font(.title)
                .fontWeight(.bold)

            Text(promptText)
                .font(.body)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(examplePrompts, id: \.self) { prompt in
                    Text("\"\(prompt)\"")
                        .font(.body)
                        .italic()
                }
            }
            .padding(.vertical, 8)

            Button(action: onOpenClient) {
                Text(openButtonTitle)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Button(action: onSkip) {
                Text("I'll try it later \u{2014} take me to Settings")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(40)
        .frame(width: 640)
    }
}
