import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Label("Majordomo", systemImage: "gearshape")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Your AI now knows your Mac.")
                .font(.title2)

            Text("Ask it to check your calendar, control your home, make a phone call, or close your windows at sunset. You decide what it can do.")
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 440)

            Button(action: onContinue) {
                Label("Get Started", systemImage: "arrow.right")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.top, 8)

            Spacer()
        }
        .padding(40)
        .frame(width: 640)
    }
}
