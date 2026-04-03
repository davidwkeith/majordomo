import Foundation
import Testing
@testable import Majordomo

// MARK: - Helpers

private func makeSystemTools(
    info: SystemInfoProviding? = nil,
    volume: VolumeControlling? = nil,
    brightness: BrightnessControlling? = nil,
    sleep: SleepControlling? = nil,
    speech: TextSpeaking? = nil,
    screenshot: ScreenshotCapturing? = nil,
    notification: NotificationSending? = nil,
    caffeinate: CaffeinateControlling? = nil
) -> SystemTools {
    SystemTools(
        info: info ?? MockSystemInfo(),
        volume: volume ?? MockVolumeControl(),
        brightness: brightness ?? MockBrightnessControl(),
        sleep: sleep ?? MockSleepControl(),
        speech: speech ?? MockTextSpeaker(),
        screenshot: screenshot ?? MockScreenshotCapture(),
        notification: notification ?? MockNotificationSender(),
        caffeinate: caffeinate ?? MockCaffeinateControl()
    )
}

// MARK: - system_get_info

@Test func getInfoReturnsSystemDetails() throws {
    let mock = MockSystemInfo(
        osVersion: "26.0",
        hostname: "test-mac",
        architecture: "arm64",
        memoryGB: 16,
        processorCount: 10
    )
    let tools = makeSystemTools(info: mock)
    let result = tools.getInfo()

    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["os_version"] == .string("26.0"))
    #expect(obj["hostname"] == .string("test-mac"))
    #expect(obj["architecture"] == .string("arm64"))
    #expect(obj["memory_gb"] == .int(16))
    #expect(obj["processor_count"] == .int(10))
}

// MARK: - system_get_volume / system_set_volume

@Test func getVolumeReturnsCurrent() throws {
    let mock = MockVolumeControl(volume: 75)
    let tools = makeSystemTools(volume: mock)
    let result = try tools.getVolume()
    #expect(result == .object(["volume": .int(75)]))
}

@Test func setVolumeUpdatesValue() throws {
    let mock = MockVolumeControl(volume: 50)
    var tools = makeSystemTools(volume: mock)
    let result = try tools.setVolume(level: 80)

    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["volume"] == .int(80))
    #expect(mock.currentVolume == 80)
}

@Test func setVolumeClampsToRange() throws {
    let mock = MockVolumeControl(volume: 50)
    var tools = makeSystemTools(volume: mock)

    _ = try tools.setVolume(level: 150)
    #expect(mock.currentVolume == 100)

    _ = try tools.setVolume(level: -10)
    #expect(mock.currentVolume == 0)
}

// MARK: - system_get_brightness / system_set_brightness

@Test func getBrightnessReturnsCurrent() throws {
    let mock = MockBrightnessControl(brightness: 60)
    let tools = makeSystemTools(brightness: mock)
    let result = try tools.getBrightness()
    #expect(result == .object(["brightness": .int(60)]))
}

@Test func setBrightnessUpdatesValue() throws {
    let mock = MockBrightnessControl(brightness: 50)
    var tools = makeSystemTools(brightness: mock)
    let result = try tools.setBrightness(level: 90)

    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["brightness"] == .int(90))
    #expect(mock.currentBrightness == 90)
}

@Test func setBrightnessClampsToRange() throws {
    let mock = MockBrightnessControl(brightness: 50)
    var tools = makeSystemTools(brightness: mock)

    _ = try tools.setBrightness(level: 200)
    #expect(mock.currentBrightness == 100)

    _ = try tools.setBrightness(level: -5)
    #expect(mock.currentBrightness == 0)
}

// MARK: - system_sleep

@Test func sleepInvokesSystem() throws {
    let mock = MockSleepControl()
    var tools = makeSystemTools(sleep: mock)
    let result = try tools.sleep()

    #expect(mock.sleepCalled)
    #expect(result == .object(["status": .string("sleeping")]))
}

// MARK: - system_say

@Test func sayInvokesWithText() throws {
    let mock = MockTextSpeaker()
    var tools = makeSystemTools(speech: mock)
    let result = try tools.say(text: "Hello world")

    #expect(mock.spokenTexts == ["Hello world"])
    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["spoken"] == .string("Hello world"))
}

@Test func sayPassesVoiceParameter() throws {
    let mock = MockTextSpeaker()
    var tools = makeSystemTools(speech: mock)
    _ = try tools.say(text: "Hi", voice: "Samantha")

    #expect(mock.lastVoice == "Samantha")
}

// MARK: - system_screenshot

@Test func screenshotCapturesScreen() async throws {
    let mock = MockScreenshotCapture(resultPath: "/tmp/screenshot.png")
    var tools = makeSystemTools(screenshot: mock)
    let result = try await tools.screenshot()

    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["path"] == .string("/tmp/screenshot.png"))
}

@Test func screenshotPassesDisplayID() async throws {
    let mock = MockScreenshotCapture(resultPath: "/tmp/shot.png")
    var tools = makeSystemTools(screenshot: mock)
    _ = try await tools.screenshot(displayID: 2)

    #expect(mock.lastDisplayID == 2)
}

// MARK: - system_notify

@Test func notifySendsNotification() async throws {
    let mock = MockNotificationSender()
    var tools = makeSystemTools(notification: mock)
    let result = try await tools.notify(title: "Alert", body: "Something happened")

    #expect(mock.sentNotifications.count == 1)
    #expect(mock.sentNotifications[0].title == "Alert")
    #expect(mock.sentNotifications[0].body == "Something happened")
    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["title"] == .string("Alert"))
}

@Test func notifyIncludesSound() async throws {
    let mock = MockNotificationSender()
    var tools = makeSystemTools(notification: mock)
    _ = try await tools.notify(title: "Alert", body: "msg", sound: true)

    #expect(mock.sentNotifications[0].sound == true)
}

// MARK: - system_caffeinate

@Test func caffeinateStartsPreventsleep() throws {
    let mock = MockCaffeinateControl()
    var tools = makeSystemTools(caffeinate: mock)
    let result = try tools.caffeinate(enabled: true)

    #expect(mock.isActive)
    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["caffeinate"] == .bool(true))
}

@Test func caffeinateStopAllowsSleep() throws {
    let mock = MockCaffeinateControl()
    mock.isActive = true
    var tools = makeSystemTools(caffeinate: mock)
    let result = try tools.caffeinate(enabled: false)

    #expect(!mock.isActive)
    guard case .object(let obj) = result else {
        Issue.record("Expected object"); return
    }
    #expect(obj["caffeinate"] == .bool(false))
}

@Test func caffeinatePassesReason() throws {
    let mock = MockCaffeinateControl()
    var tools = makeSystemTools(caffeinate: mock)
    _ = try tools.caffeinate(enabled: true, reason: "Long download")

    #expect(mock.lastReason == "Long download")
}

// MARK: - Tool Annotations

@Test func annotationsIncludeAllTools() {
    let annotations = SystemTools.toolAnnotations
    #expect(annotations.count == 10)

    // Read-only tools
    #expect(annotations["system_get_info"]?["readOnlyHint"] == true)
    #expect(annotations["system_get_volume"]?["readOnlyHint"] == true)
    #expect(annotations["system_get_brightness"]?["readOnlyHint"] == true)

    // Destructive tools
    #expect(annotations["system_sleep"]?["destructiveHint"] == true)

    // Non-read-only tools
    #expect(annotations["system_set_volume"]?["readOnlyHint"] == false)
    #expect(annotations["system_set_brightness"]?["readOnlyHint"] == false)
    #expect(annotations["system_say"]?["readOnlyHint"] == false)
    #expect(annotations["system_caffeinate"]?["readOnlyHint"] == false)
}
