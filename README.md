# Majordomo

A macOS menu bar AI assistant that exposes system tools through an MCP server and OpenAI-compatible API. Control your Mac with natural language via voice or text.

## Features

- **Menu bar app** -- lives in your status bar, always accessible
- **Voice input** -- push-to-talk with on-device speech recognition
- **MCP server** -- exposes macOS tools (calendar, contacts, reminders, music, files, clipboard, accessibility, shortcuts, scripts, notifications, system info) to any MCP client
- **OpenAI-compatible API** -- connect from any client that speaks the OpenAI chat format
- **Siri Shortcuts integration** -- App Intents for running tasks, invoking tools, and checking status
- **Onboarding** -- auto-detects MCP clients (Claude, Cursor, etc.) and patches their config

## Requirements

- macOS 26+
- Xcode 26+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

## Getting Started

```bash
# Generate the Xcode project
xcodegen generate

# Open in Xcode
open Majordomo.xcodeproj

# Or build from the command line
xcodebuild -project Majordomo.xcodeproj -scheme Majordomo -destination 'platform=macOS'
```

## Running Tests

```bash
xcodebuild test -project Majordomo.xcodeproj -scheme MajordomoTests -destination 'platform=macOS'
```

Regenerate the project with `xcodegen generate` after adding or removing source/test files.

## Project Structure

```
App/            Application entry point and delegate
CLI/            Command-line interface tool
Intents/        Siri Shortcuts / App Intents
Onboarding/     MCP client detection and config patching
Permissions/    System permission management
Plugins/        Plugin support
Prompts/        System prompt definitions
Registry/       Tool registry
Server/         HTTP server and protocol adapters (MCP, OpenAI, OpenAPI)
Tools/          macOS system tool implementations
UI/             SwiftUI views (menu bar, onboarding, permissions, voice overlay)
Voice/          Speech recognition, hotkey monitoring, voice session management
Tests/          Unit tests (Swift Testing)
```

## License

[ISC](LICENSE)
