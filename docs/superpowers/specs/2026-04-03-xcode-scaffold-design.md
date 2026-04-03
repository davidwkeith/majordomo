# Xcode Project Scaffold Design

**Status:** Approved
**Date:** 2026-04-03

---

## Scope

Skeleton-only Xcode project scaffold for Majordomo. All files compile but contain minimal stubs. No functional code beyond what the compiler requires.

## Xcode Project

- **Project name:** Majordomo
- **Project file:** `Majordomo.xcodeproj` at repo root
- **Targets:**
  - `Majordomo` — macOS app (SwiftUI lifecycle)
  - `majordomo-cli` — macOS command-line tool
- **Deployment target:** macOS 26.0
- **Swift language version:** 6
- **Bundle IDs:** `app.majordomo` (app), `app.majordomo.cli` (CLI)
- **Shared code strategy:** Target membership on individual files (no packages or frameworks)

## Folder Structure

Matches section 3.2 of the technical requirements doc. Folder groups in Xcode mirror directories on disk.

```
Majordomo/
├── Majordomo.xcodeproj
├── docs/
├── App/
│   ├── MajordomoApp.swift
│   └── AppDelegate.swift
├── Server/
│   ├── InterfaceServer.swift
│   ├── MCPAdapter.swift
│   ├── OpenAIAdapter.swift
│   ├── OpenAPIAdapter.swift
│   └── CLIAdapter.swift
├── Registry/
│   └── ToolRegistry.swift
├── Tools/
│   ├── SystemTools.swift
│   ├── FileTools.swift
│   ├── ClipboardTools.swift
│   ├── CalendarTools.swift
│   ├── ReminderTools.swift
│   ├── ContactsTools.swift
│   ├── NotificationTools.swift
│   ├── MusicTools.swift
│   ├── AppTools.swift
│   ├── AccessibilityTools.swift
│   ├── ShortcutsTools.swift
│   └── ScriptTools.swift
├── Prompts/
│   └── MacOSCoworkerPrompt.swift
├── Intents/
│   ├── RunAssistantTaskIntent.swift
│   ├── RunMCPToolIntent.swift
│   └── GetStatusIntent.swift
├── Permissions/
│   ├── PermissionManager.swift
│   └── PermissionModel.swift
├── Plugins/
├── UI/
│   ├── ContentView.swift
│   ├── PermissionDashboard.swift
│   ├── PermissionRow.swift
│   └── ServerStatusBar.swift
└── CLI/
    └── main.swift
```

## Entitlements

`Majordomo.entitlements` for the app target:

- `com.apple.security.app-sandbox = NO` — requires direct system access (AXUIElement, AppleScript, Process)
- `com.apple.security.network.server = YES` — localhost HTTP listener
- `com.apple.security.network.client = YES` — Ollama detection, API calls

## File Contents

Every `.swift` file is a minimal stub that compiles:

- `MajordomoApp.swift` — `@main` App struct with `ContentView` in a `WindowGroup`
- `AppDelegate.swift` — empty `NSApplicationDelegate` conformance
- `ContentView.swift` — displays "Majordomo" text
- `main.swift` (CLI) — prints usage message and exits
- All other files — empty structs or `// TODO` placeholders

## Decisions

- **No sandbox:** The app needs direct access to AXUIElement, NSAppleScript, Process, NSPasteboard, and other system APIs that don't work inside the App Sandbox.
- **Folder groups = disk directories:** Keeps Xcode groups in sync with the filesystem for easier navigation outside Xcode.
- **No internal Swift package yet:** At the skeleton stage there's no shared code. Target membership is sufficient. Can promote to a local package when core types are built out.
- **CLI as separate target (not embedded):** The CLI binary will be installed to `/usr/local/bin/majordomo` and communicates with the app over localhost. It doesn't need to be embedded in the app bundle.
