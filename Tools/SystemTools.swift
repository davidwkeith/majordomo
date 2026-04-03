import Foundation
import CoreAudio
import IOKit
import IOKit.pwr_mgt
import ScreenCaptureKit
import UserNotifications
import AppKit
import AVFoundation

// MARK: - SystemInfoProviding

/// Protocol for querying system information.
protocol SystemInfoProviding {
    var osVersion: String { get }
    var hostname: String { get }
    var architecture: String { get }
    var memoryGB: Int { get }
    var processorCount: Int { get }
}

/// Real implementation using ProcessInfo and uname.
struct DefaultSystemInfo: SystemInfoProviding {
    var osVersion: String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        return "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    }

    var hostname: String {
        ProcessInfo.processInfo.hostName
    }

    var architecture: String {
        var sysinfo = utsname()
        uname(&sysinfo)
        return withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }

    var memoryGB: Int {
        Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024))
    }

    var processorCount: Int {
        ProcessInfo.processInfo.processorCount
    }
}

/// Mock for testing.
final class MockSystemInfo: SystemInfoProviding {
    let osVersion: String
    let hostname: String
    let architecture: String
    let memoryGB: Int
    let processorCount: Int

    init(
        osVersion: String = "26.0.0",
        hostname: String = "mock-mac",
        architecture: String = "arm64",
        memoryGB: Int = 16,
        processorCount: Int = 10
    ) {
        self.osVersion = osVersion
        self.hostname = hostname
        self.architecture = architecture
        self.memoryGB = memoryGB
        self.processorCount = processorCount
    }
}

// MARK: - VolumeControlling

/// Protocol for system volume control.
protocol VolumeControlling: AnyObject {
    var currentVolume: Int { get set }
    func getVolume() throws -> Int
    func setVolume(_ level: Int) throws
}

/// Real implementation using CoreAudio.
final class CoreAudioVolumeControl: VolumeControlling {
    var currentVolume: Int = 50

    private var defaultOutputDeviceID: AudioDeviceID {
        var deviceID = AudioDeviceID(kAudioObjectUnknown)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID
        )
        return deviceID
    }

    func getVolume() throws -> Int {
        var volume: Float32 = 0
        var size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(defaultOutputDeviceID, &address, 0, nil, &size, &volume)
        guard status == noErr else {
            throw SystemToolsError.audioError(status)
        }
        currentVolume = Int(volume * 100)
        return currentVolume
    }

    func setVolume(_ level: Int) throws {
        let clamped = min(max(level, 0), 100)
        var volume = Float32(clamped) / 100.0
        let size = UInt32(MemoryLayout<Float32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMainVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectSetPropertyData(defaultOutputDeviceID, &address, 0, nil, size, &volume)
        guard status == noErr else {
            throw SystemToolsError.audioError(status)
        }
        currentVolume = clamped
    }
}

/// Mock for testing.
final class MockVolumeControl: VolumeControlling {
    var currentVolume: Int

    init(volume: Int = 50) {
        self.currentVolume = volume
    }

    func getVolume() throws -> Int { currentVolume }

    func setVolume(_ level: Int) throws {
        currentVolume = min(max(level, 0), 100)
    }
}

// MARK: - BrightnessControlling

/// Protocol for display brightness control.
protocol BrightnessControlling: AnyObject {
    var currentBrightness: Int { get set }
    func getBrightness() throws -> Int
    func setBrightness(_ level: Int) throws
}

/// Real implementation using IOKit.
final class IOKitBrightnessControl: BrightnessControlling {
    var currentBrightness: Int = 50

    func getBrightness() throws -> Int {
        var iterator = io_iterator_t()
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard result == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(result)
        }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        defer { if service != 0 { IOObjectRelease(service) } }

        guard service != 0 else {
            throw SystemToolsError.noDisplay
        }

        var brightness: Float = 0
        let err = IODisplayGetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, &brightness)
        guard err == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(err)
        }
        currentBrightness = Int(brightness * 100)
        return currentBrightness
    }

    func setBrightness(_ level: Int) throws {
        let clamped = min(max(level, 0), 100)
        var iterator = io_iterator_t()
        let result = IOServiceGetMatchingServices(
            kIOMainPortDefault,
            IOServiceMatching("IODisplayConnect"),
            &iterator
        )
        guard result == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(result)
        }
        defer { IOObjectRelease(iterator) }

        let service = IOIteratorNext(iterator)
        defer { if service != 0 { IOObjectRelease(service) } }

        guard service != 0 else {
            throw SystemToolsError.noDisplay
        }

        let err = IODisplaySetFloatParameter(service, 0, kIODisplayBrightnessKey as CFString, Float(clamped) / 100.0)
        guard err == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(err)
        }
        currentBrightness = clamped
    }
}

/// Mock for testing.
final class MockBrightnessControl: BrightnessControlling {
    var currentBrightness: Int

    init(brightness: Int = 50) {
        self.currentBrightness = brightness
    }

    func getBrightness() throws -> Int { currentBrightness }

    func setBrightness(_ level: Int) throws {
        currentBrightness = min(max(level, 0), 100)
    }
}

// MARK: - SleepControlling

/// Protocol for system sleep control.
protocol SleepControlling: AnyObject {
    func performSleep() throws
}

/// Real implementation using IOKit IOPMSleepSystem.
final class IOKitSleepControl: SleepControlling {
    func performSleep() throws {
        let port = IOPMFindPowerManagement(mach_port_t(MACH_PORT_NULL))
        guard port != 0 else {
            throw SystemToolsError.sleepFailed
        }
        let result = IOPMSleepSystem(port)
        IOServiceClose(port)
        guard result == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(result)
        }
    }
}

/// Mock for testing.
final class MockSleepControl: SleepControlling {
    var sleepCalled = false

    func performSleep() throws {
        sleepCalled = true
    }
}

// MARK: - TextSpeaking

/// Protocol for text-to-speech.
protocol TextSpeaking: AnyObject {
    func speak(_ text: String, voice: String?) throws
}

/// Real implementation using AVSpeechSynthesizer.
final class AVSpeechSynthesizerSpeaker: TextSpeaking {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String, voice: String?) throws {
        let utterance = AVSpeechUtterance(string: text)
        if let voice {
            utterance.voice = AVSpeechSynthesisVoice(identifier: voice)
                ?? AVSpeechSynthesisVoice(language: voice)
        }
        synthesizer.speak(utterance)
    }
}

/// Mock for testing.
final class MockTextSpeaker: TextSpeaking {
    var spokenTexts: [String] = []
    var lastVoice: String?

    func speak(_ text: String, voice: String?) throws {
        spokenTexts.append(text)
        lastVoice = voice
    }
}

// MARK: - ScreenshotCapturing

/// Protocol for screen capture.
protocol ScreenshotCapturing: AnyObject {
    func capture(displayID: Int?) async throws -> String
}

/// Real implementation using ScreenCaptureKit.
final class SCScreenshotCapture: ScreenshotCapturing {
    func capture(displayID: Int?) async throws -> String {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        let display: SCDisplay
        if let displayID, let match = content.displays.first(where: { Int($0.displayID) == displayID }) {
            display = match
        } else {
            guard let primary = content.displays.first else {
                throw SystemToolsError.noDisplay
            }
            display = primary
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        let timestamp = ISO8601DateFormatter().string(from: Date())
        let filename = "screenshot-\(timestamp).png"
        let path = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        let rep = NSBitmapImageRep(cgImage: image)
        guard let pngData = rep.representation(using: .png, properties: [:]) else {
            throw SystemToolsError.screenshotEncodingFailed
        }
        try pngData.write(to: path)

        return path.path
    }
}

/// Mock for testing.
final class MockScreenshotCapture: ScreenshotCapturing {
    let resultPath: String
    var lastDisplayID: Int?

    init(resultPath: String = "/tmp/screenshot.png") {
        self.resultPath = resultPath
    }

    func capture(displayID: Int?) async throws -> String {
        lastDisplayID = displayID
        return resultPath
    }
}

// MARK: - NotificationSending

/// Protocol for sending user notifications.
protocol NotificationSending: AnyObject {
    func send(title: String, body: String, sound: Bool) async throws
}

/// Recorded notification for testing.
struct RecordedNotification: Equatable {
    let title: String
    let body: String
    let sound: Bool
}

/// Real implementation using UNUserNotificationCenter.
final class UNNotificationSender: NotificationSending {
    func send(title: String, body: String, sound: Bool) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        guard granted else {
            throw SystemToolsError.notificationDenied
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        if sound {
            content.sound = .default
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        try await center.add(request)
    }
}

/// Mock for testing.
final class MockNotificationSender: NotificationSending {
    var sentNotifications: [RecordedNotification] = []

    func send(title: String, body: String, sound: Bool) async throws {
        sentNotifications.append(RecordedNotification(title: title, body: body, sound: sound))
    }
}

// MARK: - CaffeinateControlling

/// Protocol for preventing system sleep.
protocol CaffeinateControlling: AnyObject {
    var isActive: Bool { get set }
    func start(reason: String?) throws
    func stop() throws
}

/// Real implementation using IOKit power assertions.
final class IOKitCaffeinateControl: CaffeinateControlling {
    var isActive: Bool = false
    private var assertionID: IOPMAssertionID = 0

    func start(reason: String?) throws {
        guard !isActive else { return }
        let reasonStr = (reason ?? "Majordomo caffeinate") as CFString
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertionTypeNoIdleSleep as CFString,
            UInt32(kIOPMAssertionLevelOn),
            reasonStr,
            &assertionID
        )
        guard result == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(result)
        }
        isActive = true
    }

    func stop() throws {
        guard isActive else { return }
        let result = IOPMAssertionRelease(assertionID)
        guard result == kIOReturnSuccess else {
            throw SystemToolsError.ioKitError(result)
        }
        assertionID = 0
        isActive = false
    }
}

/// Mock for testing.
final class MockCaffeinateControl: CaffeinateControlling {
    var isActive: Bool = false
    var lastReason: String?

    func start(reason: String?) throws {
        isActive = true
        lastReason = reason
    }

    func stop() throws {
        isActive = false
    }
}

// MARK: - Errors

/// Errors from system tool operations.
enum SystemToolsError: Error {
    case audioError(OSStatus)
    case ioKitError(IOReturn)
    case noDisplay
    case sleepFailed
    case speechFailed
    case screenshotEncodingFailed
    case notificationDenied
}

// MARK: - SystemTools

/// Volume, brightness, sleep, say, screenshot, notify, caffeinate.
struct SystemTools {
    private let info: SystemInfoProviding
    private let volume: VolumeControlling
    private let brightness: BrightnessControlling
    private let sleepControl: SleepControlling
    private let speech: TextSpeaking
    private let screenshotCapture: ScreenshotCapturing
    private let notification: NotificationSending
    private let caffeinateControl: CaffeinateControlling

    init(
        info: SystemInfoProviding,
        volume: VolumeControlling,
        brightness: BrightnessControlling,
        sleep: SleepControlling,
        speech: TextSpeaking,
        screenshot: ScreenshotCapturing,
        notification: NotificationSending,
        caffeinate: CaffeinateControlling
    ) {
        self.info = info
        self.volume = volume
        self.brightness = brightness
        self.sleepControl = sleep
        self.speech = speech
        self.screenshotCapture = screenshot
        self.notification = notification
        self.caffeinateControl = caffeinate
    }

    /// Convenience initializer with real system implementations.
    init() {
        self.init(
            info: DefaultSystemInfo(),
            volume: CoreAudioVolumeControl(),
            brightness: IOKitBrightnessControl(),
            sleep: IOKitSleepControl(),
            speech: AVSpeechSynthesizerSpeaker(),
            screenshot: SCScreenshotCapture(),
            notification: UNNotificationSender(),
            caffeinate: IOKitCaffeinateControl()
        )
    }

    // MARK: - system_get_info

    func getInfo() -> JSONValue {
        .object([
            "os_version": .string(info.osVersion),
            "hostname": .string(info.hostname),
            "architecture": .string(info.architecture),
            "memory_gb": .int(info.memoryGB),
            "processor_count": .int(info.processorCount)
        ])
    }

    // MARK: - system_get_volume / system_set_volume

    func getVolume() throws -> JSONValue {
        let level = try volume.getVolume()
        return .object(["volume": .int(level)])
    }

    mutating func setVolume(level: Int) throws -> JSONValue {
        let clamped = min(max(level, 0), 100)
        try volume.setVolume(clamped)
        return .object(["volume": .int(clamped)])
    }

    // MARK: - system_get_brightness / system_set_brightness

    func getBrightness() throws -> JSONValue {
        let level = try brightness.getBrightness()
        return .object(["brightness": .int(level)])
    }

    mutating func setBrightness(level: Int) throws -> JSONValue {
        let clamped = min(max(level, 0), 100)
        try brightness.setBrightness(clamped)
        return .object(["brightness": .int(clamped)])
    }

    // MARK: - system_sleep

    mutating func sleep() throws -> JSONValue {
        try sleepControl.performSleep()
        return .object(["status": .string("sleeping")])
    }

    // MARK: - system_say

    mutating func say(text: String, voice: String? = nil) throws -> JSONValue {
        try speech.speak(text, voice: voice)
        return .object(["spoken": .string(text)])
    }

    // MARK: - system_screenshot

    mutating func screenshot(displayID: Int? = nil) async throws -> JSONValue {
        let path = try await screenshotCapture.capture(displayID: displayID)
        return .object(["path": .string(path)])
    }

    // MARK: - system_notify

    mutating func notify(title: String, body: String, sound: Bool = true) async throws -> JSONValue {
        try await notification.send(title: title, body: body, sound: sound)
        return .object([
            "title": .string(title),
            "body": .string(body),
            "sound": .bool(sound)
        ])
    }

    // MARK: - system_caffeinate

    mutating func caffeinate(enabled: Bool, reason: String? = nil) throws -> JSONValue {
        if enabled {
            try caffeinateControl.start(reason: reason)
        } else {
            try caffeinateControl.stop()
        }
        return .object(["caffeinate": .bool(enabled)])
    }

    // MARK: - Tool Annotations

    /// MCP tool annotations for each system tool.
    static let toolAnnotations: [String: [String: Bool]] = [
        "system_get_info": ["readOnlyHint": true],
        "system_get_volume": ["readOnlyHint": true],
        "system_get_brightness": ["readOnlyHint": true],
        "system_set_volume": ["readOnlyHint": false],
        "system_set_brightness": ["readOnlyHint": false],
        "system_sleep": ["readOnlyHint": false, "destructiveHint": true],
        "system_say": ["readOnlyHint": false],
        "system_screenshot": ["readOnlyHint": false],
        "system_notify": ["readOnlyHint": false],
        "system_caffeinate": ["readOnlyHint": false],
    ]
}
