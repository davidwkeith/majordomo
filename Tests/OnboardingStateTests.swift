import Testing
@testable import Majordomo

struct MockKeyValueStore: KeyValueStore {
    var storage: [String: Any] = [:]

    func bool(forKey key: String) -> Bool {
        storage[key] as? Bool ?? false
    }

    mutating func set(_ value: Bool, forKey key: String) {
        storage[key] = value
    }
}

@Test func freshStateShowsOnboarding() {
    let store = MockKeyValueStore()
    let state = OnboardingState(store: store)
    #expect(state.shouldShowOnboarding == true)
    #expect(state.shouldShowReEntry == false)
}

@Test func completedOnboardingHidesOnboarding() {
    let store = MockKeyValueStore()
    var state = OnboardingState(store: store)
    state.completeOnboarding()
    #expect(state.shouldShowOnboarding == false)
}

@Test func completedOnboardingWithoutToolCallShowsReEntry() {
    var store = MockKeyValueStore()
    store.set(true, forKey: "hasCompletedOnboarding")
    let state = OnboardingState(store: store)
    #expect(state.shouldShowOnboarding == false)
    #expect(state.shouldShowReEntry == true)
}

@Test func completedOnboardingWithToolCallHidesReEntry() {
    var store = MockKeyValueStore()
    store.set(true, forKey: "hasCompletedOnboarding")
    store.set(true, forKey: "hasHadSuccessfulToolCall")
    let state = OnboardingState(store: store)
    #expect(state.shouldShowOnboarding == false)
    #expect(state.shouldShowReEntry == false)
}

@Test func recordToolCallPersists() {
    let store = MockKeyValueStore()
    var state = OnboardingState(store: store)
    state.recordSuccessfulToolCall()
    #expect(state.hasHadSuccessfulToolCall == true)
}

@Test func completeOnboardingPersists() {
    let store = MockKeyValueStore()
    var state = OnboardingState(store: store)
    state.completeOnboarding()
    #expect(state.hasCompletedOnboarding == true)
}
