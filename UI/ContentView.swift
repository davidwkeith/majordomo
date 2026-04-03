import SwiftUI

struct ContentView: View {
    var showReEntry: Bool = false
    var onReEntry: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            if showReEntry {
                HStack {
                    Text("Looks like you haven't connected an AI yet. Want to try again?")
                        .font(.callout)
                    Spacer()
                    Button("Try again") {
                        onReEntry?()
                    }
                }
                .padding()
                .background(Color.accentColor.opacity(0.1))
            }

            Text("Majordomo")
                .font(.largeTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
