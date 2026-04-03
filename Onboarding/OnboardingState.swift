import Foundation

/// Protocol for key-value persistence, enabling injectable storage for testing.
protocol KeyValueStore {
    func bool(forKey key: String) -> Bool
    mutating func set(_ value: Bool, forKey key: String)
}

extension UserDefaults: KeyValueStore {}

/// Tracks onboarding progress and persists state across app launches.
struct OnboardingState {
    private(set) var hasCompletedOnboarding: Bool
    private(set) var hasHadSuccessfulToolCall: Bool

    private var store: any KeyValueStore

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasHadSuccessfulToolCall = "hasHadSuccessfulToolCall"
    }

    init(store: any KeyValueStore) {
        self.store = store
        self.hasCompletedOnboarding = store.bool(forKey: Keys.hasCompletedOnboarding)
        self.hasHadSuccessfulToolCall = store.bool(forKey: Keys.hasHadSuccessfulToolCall)
    }

    /// True when the user has not yet completed onboarding.
    var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding
    }

    /// True when onboarding was completed but no successful tool call has ever occurred.
    var shouldShowReEntry: Bool {
        hasCompletedOnboarding && !hasHadSuccessfulToolCall
    }

    mutating func completeOnboarding() {
        hasCompletedOnboarding = true
        store.set(true, forKey: Keys.hasCompletedOnboarding)
    }

    mutating func recordSuccessfulToolCall() {
        hasHadSuccessfulToolCall = true
        store.set(true, forKey: Keys.hasHadSuccessfulToolCall)
    }
}
