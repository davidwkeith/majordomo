import SwiftUI

@main
struct MajordomoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var onboardingState = OnboardingState(store: UserDefaults.standard)
    @State private var forceShowOnboarding = false

    private var shouldShowOnboarding: Bool {
        onboardingState.shouldShowOnboarding || forceShowOnboarding
    }

    var body: some Scene {
        WindowGroup {
            if shouldShowOnboarding {
                OnboardingFlowView {
                    onboardingState.completeOnboarding()
                    forceShowOnboarding = false
                }
            } else {
                ContentView(
                    showReEntry: onboardingState.shouldShowReEntry,
                    onReEntry: {
                        forceShowOnboarding = true
                    }
                )
            }
        }
        .defaultSize(width: 640, height: 480)
    }
}
