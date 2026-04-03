# Majordomo

macOS menu bar AI assistant. Swift 6, macOS 26 deployment target.

## Build & Test

- `xcodegen generate` — regenerate Xcode project after adding/removing files or changing project.yml
- `xcodebuild test -project Majordomo.xcodeproj -scheme MajordomoTests -destination 'platform=macOS'` — run tests
- Must regenerate with xcodegen before tests will pick up new source/test files

## Architecture

- Protocol-based dependency injection for all framework dependencies (e.g. `KeyValueStore`, `SpeechRecognizing`, `GlobalHotkeyMonitoring`)
- Mocks live alongside their protocols in the production source, not in test files
- Source organized by domain: App/, Voice/, Onboarding/, Permissions/, Tools/, UI/, Server/, etc.
- Tests in Tests/ directory, flat (no subdirectories)

## Code Style

- Swift Testing framework (`import Testing`, `@Test`, `#expect`) — NOT XCTest
- `@testable import Majordomo` for all tests
- Swift 6 strict concurrency: use `@MainActor` on classes that capture `self` in `Task` closures
- Structs for pure state models, classes for services with framework dependencies
- `AsyncStream<T>` for event delivery (transcripts, hotkey activations)

## Gotchas

- SourceKit diagnostics ("Cannot find type in scope") lag behind actual builds — trust xcodebuild output over IDE errors
- `AsyncStream` build closure runs eagerly on construction — affects mock design (don't set state that should persist after stream creation)
- XcodeGen is the source of truth — never edit project.pbxproj manually
