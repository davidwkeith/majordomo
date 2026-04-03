# Xcode Project Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a compiling Xcode project with app and CLI targets, folder structure matching the technical requirements doc, entitlements, and minimal Swift stubs.

**Architecture:** XcodeGen generates the `.xcodeproj` from a `project.yml` spec. All Swift source files are minimal stubs. The app target uses SwiftUI lifecycle; the CLI target is a standalone command-line tool.

**Tech Stack:** Swift 6, SwiftUI, macOS 26, XcodeGen 2.44.1

---

### Task 1: Create directory structure and entitlements

**Files:**
- Create: `App/MajordomoApp.swift`
- Create: `App/AppDelegate.swift`
- Create: `Server/InterfaceServer.swift`
- Create: `Server/MCPAdapter.swift`
- Create: `Server/OpenAIAdapter.swift`
- Create: `Server/OpenAPIAdapter.swift`
- Create: `Server/CLIAdapter.swift`
- Create: `Registry/ToolRegistry.swift`
- Create: `Tools/SystemTools.swift`
- Create: `Tools/FileTools.swift`
- Create: `Tools/ClipboardTools.swift`
- Create: `Tools/CalendarTools.swift`
- Create: `Tools/ReminderTools.swift`
- Create: `Tools/ContactsTools.swift`
- Create: `Tools/NotificationTools.swift`
- Create: `Tools/MusicTools.swift`
- Create: `Tools/AppTools.swift`
- Create: `Tools/AccessibilityTools.swift`
- Create: `Tools/ShortcutsTools.swift`
- Create: `Tools/ScriptTools.swift`
- Create: `Prompts/MacOSCoworkerPrompt.swift`
- Create: `Intents/RunAssistantTaskIntent.swift`
- Create: `Intents/RunMCPToolIntent.swift`
- Create: `Intents/GetStatusIntent.swift`
- Create: `Permissions/PermissionManager.swift`
- Create: `Permissions/PermissionModel.swift`
- Create: `Plugins/.gitkeep`
- Create: `UI/ContentView.swift`
- Create: `UI/PermissionDashboard.swift`
- Create: `UI/PermissionRow.swift`
- Create: `UI/ServerStatusBar.swift`
- Create: `CLI/main.swift`
- Create: `Majordomo.entitlements`

- [ ] **Step 1: Create all directories**

```bash
mkdir -p App Server Registry Tools Prompts Intents Permissions Plugins UI CLI
```

- [ ] **Step 2: Create App stubs**

`App/MajordomoApp.swift`:
```swift
import SwiftUI

@main
struct MajordomoApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

`App/AppDelegate.swift`:
```swift
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // TODO: Start server, register tools
    }
}
```

- [ ] **Step 3: Create Server stubs**

`Server/InterfaceServer.swift`:
```swift
import Foundation

/// HTTP listener that routes requests to protocol adapters.
struct InterfaceServer {
    // TODO: Network.framework listener on localhost:<port>
}
```

`Server/MCPAdapter.swift`:
```swift
import Foundation

/// MCP 2025-03-26 protocol adapter.
struct MCPAdapter {
    // TODO: JSON-RPC dispatch for MCP methods
}
```

`Server/OpenAIAdapter.swift`:
```swift
import Foundation

/// OpenAI function calling format adapter.
struct OpenAIAdapter {
    // TODO: Translate OpenAI tool_calls to/from internal ToolCall
}
```

`Server/OpenAPIAdapter.swift`:
```swift
import Foundation

/// Generates /openapi.json from the tool registry.
struct OpenAPIAdapter {
    // TODO: Dynamic OpenAPI 3.1 spec generation
}
```

`Server/CLIAdapter.swift`:
```swift
import Foundation

/// stdin/stdout JSON protocol adapter for the CLI binary.
struct CLIAdapter {
    // TODO: Parse CLI JSON requests, return CLI JSON responses
}
```

- [ ] **Step 4: Create Registry stub**

`Registry/ToolRegistry.swift`:
```swift
import Foundation

/// Single source of truth for all tools and prompts.
struct ToolRegistry {
    // TODO: Tool registration, lookup, and listing
}
```

- [ ] **Step 5: Create Tools stubs**

Each file follows the same pattern — an empty struct named after its domain:

`Tools/SystemTools.swift`:
```swift
import Foundation

/// Volume, brightness, sleep, say, screenshot.
struct SystemTools {
    // TODO
}
```

`Tools/FileTools.swift`:
```swift
import Foundation

/// Spotlight search (NSMetadataQuery), mdls.
struct FileTools {
    // TODO
}
```

`Tools/ClipboardTools.swift`:
```swift
import Foundation

/// NSPasteboard read/write.
struct ClipboardTools {
    // TODO
}
```

`Tools/CalendarTools.swift`:
```swift
import Foundation

/// EventKit calendar access.
struct CalendarTools {
    // TODO
}
```

`Tools/ReminderTools.swift`:
```swift
import Foundation

/// EventKit reminders access.
struct ReminderTools {
    // TODO
}
```

`Tools/ContactsTools.swift`:
```swift
import Foundation

/// Contacts.framework access.
struct ContactsTools {
    // TODO
}
```

`Tools/NotificationTools.swift`:
```swift
import Foundation

/// UNUserNotificationCenter.
struct NotificationTools {
    // TODO
}
```

`Tools/MusicTools.swift`:
```swift
import Foundation

/// MusicKit access.
struct MusicTools {
    // TODO
}
```

`Tools/AppTools.swift`:
```swift
import Foundation

/// NSWorkspace app launch/query.
struct AppTools {
    // TODO
}
```

`Tools/AccessibilityTools.swift`:
```swift
import Foundation

/// AXUIElement automation.
struct AccessibilityTools {
    // TODO
}
```

`Tools/ShortcutsTools.swift`:
```swift
import Foundation

/// Process-based shortcuts CLI integration.
struct ShortcutsTools {
    // TODO
}
```

`Tools/ScriptTools.swift`:
```swift
import Foundation

/// NSAppleScript for Mail, Messages, Safari.
struct ScriptTools {
    // TODO
}
```

- [ ] **Step 6: Create Prompts stub**

`Prompts/MacOSCoworkerPrompt.swift`:
```swift
import Foundation

/// MCP prompt resource: the "Good Coworker" system prompt.
struct MacOSCoworkerPrompt {
    // TODO
}
```

- [ ] **Step 7: Create Intents stubs**

`Intents/RunAssistantTaskIntent.swift`:
```swift
import Foundation

/// App Intent: run a free-form assistant task via Siri/Shortcuts.
struct RunAssistantTaskIntent {
    // TODO: AppIntent conformance
}
```

`Intents/RunMCPToolIntent.swift`:
```swift
import Foundation

/// App Intent: run a specific MCP tool by name via Siri/Shortcuts.
struct RunMCPToolIntent {
    // TODO: AppIntent conformance
}
```

`Intents/GetStatusIntent.swift`:
```swift
import Foundation

/// App Intent: get Majordomo server status via Siri/Shortcuts.
struct GetStatusIntent {
    // TODO: AppIntent conformance
}
```

- [ ] **Step 8: Create Permissions stubs**

`Permissions/PermissionManager.swift`:
```swift
import Foundation

/// TCC status checking and permission request logic.
struct PermissionManager {
    // TODO
}
```

`Permissions/PermissionModel.swift`:
```swift
import Foundation

/// Data model for permission state.
struct PermissionModel {
    // TODO
}
```

- [ ] **Step 9: Create Plugins placeholder**

```bash
touch Plugins/.gitkeep
```

- [ ] **Step 10: Create UI stubs**

`UI/ContentView.swift`:
```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("Majordomo")
            .font(.largeTitle)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

`UI/PermissionDashboard.swift`:
```swift
import SwiftUI

/// Main permissions list view.
struct PermissionDashboard: View {
    var body: some View {
        Text("Permissions")
    }
}
```

`UI/PermissionRow.swift`:
```swift
import SwiftUI

/// Expandable row component for a single permission.
struct PermissionRow: View {
    var body: some View {
        Text("Permission Row")
    }
}
```

`UI/ServerStatusBar.swift`:
```swift
import SwiftUI

/// Running/stopped status strip.
struct ServerStatusBar: View {
    var body: some View {
        Text("Server Status")
    }
}
```

- [ ] **Step 11: Create CLI entry point**

`CLI/main.swift`:
```swift
import Foundation

let args = CommandLine.arguments
if args.count < 2 {
    print("""
    Usage: majordomo <command> [arguments]

    Commands:
      tools       List available tools
      run         Call a tool with JSON parameters
      schema      Get tool schema
      status      Check server status

    Majordomo.app must be running.
    """)
    exit(0)
}

print("error: not yet implemented", to: &standardError)
exit(1)

var standardError = FileHandle.standardError

extension FileHandle: @retroactive TextOutputStream {
    public func write(_ string: String) {
        let data = Data(string.utf8)
        self.write(data)
    }
}
```

- [ ] **Step 12: Create entitlements file**

`Majordomo.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
</dict>
</plist>
```

- [ ] **Step 13: Commit all source files**

```bash
git add App/ Server/ Registry/ Tools/ Prompts/ Intents/ Permissions/ Plugins/ UI/ CLI/ Majordomo.entitlements
git commit -m "feat: add Swift source stubs and entitlements for Xcode scaffold"
```

---

### Task 2: Create XcodeGen project spec and generate .xcodeproj

**Files:**
- Create: `project.yml`
- Create: `.gitignore`
- Generate: `Majordomo.xcodeproj`

- [ ] **Step 1: Create project.yml**

`project.yml`:
```yaml
name: Majordomo
options:
  bundleIdPrefix: app
  deploymentTarget:
    macOS: "26.0"
  xcodeVersion: "26.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true

settings:
  base:
    SWIFT_VERSION: "6"
    MACOSX_DEPLOYMENT_TARGET: "26.0"

targets:
  Majordomo:
    type: application
    platform: macOS
    sources:
      - path: App
      - path: Server
      - path: Registry
      - path: Tools
      - path: Prompts
      - path: Intents
      - path: Permissions
      - path: UI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.majordomo
        CODE_SIGN_ENTITLEMENTS: Majordomo.entitlements
        INFOPLIST_GENERATION_MODE: GeneratedByXcode
        PRODUCT_NAME: Majordomo
        GENERATE_INFOPLIST_FILE: "YES"
        INFOPLIST_KEY_LSApplicationCategoryType: "public.app-category.utilities"
        INFOPLIST_KEY_CFBundleDisplayName: Majordomo

  majordomo-cli:
    type: tool
    platform: macOS
    sources:
      - path: CLI
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: app.majordomo.cli
        PRODUCT_NAME: majordomo
        INFOPLIST_GENERATION_MODE: GeneratedByXcode
        GENERATE_INFOPLIST_FILE: "YES"
```

- [ ] **Step 2: Create .gitignore**

`.gitignore`:
```
# Xcode
Majordomo.xcodeproj/xcuserdata/
Majordomo.xcodeproj/project.xcworkspace/xcuserdata/
Majordomo.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/

# Build
build/
DerivedData/
*.xcresult

# macOS
.DS_Store

# XcodeGen — project is regenerable
# Majordomo.xcodeproj/
```

Note: The `.xcodeproj` is NOT gitignored — it's committed so contributors who don't have XcodeGen can clone and build. The comment documents that it's regenerable.

- [ ] **Step 3: Generate the Xcode project**

```bash
xcodegen generate
```

Expected output: `⚙ Generating plists...` then `Created project Majordomo`

- [ ] **Step 4: Verify the project compiles**

```bash
xcodebuild -project Majordomo.xcodeproj -scheme Majordomo -destination "platform=macOS" build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

```bash
xcodebuild -project Majordomo.xcodeproj -scheme majordomo-cli -destination "platform=macOS" build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit project spec, gitignore, and generated project**

```bash
git add project.yml .gitignore Majordomo.xcodeproj
git commit -m "feat: add XcodeGen spec and generate Xcode project with app + CLI targets"
```

---
