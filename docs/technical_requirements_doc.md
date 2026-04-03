# Majordomo — Technical Requirements Document

**Status:** Draft  
**Version:** 0.2  
**Platform:** macOS 26 (Tahoe) and later  

---

## 1. Purpose

### 1.1 A New Category of Software

Majordomo is a **Personal AI Runtime** — a new category of macOS software that gives AI agents trusted, permissioned access to the personal computing environment. Unlike traditional applications, which provide fixed features controlled by the developer, a Personal AI Runtime exposes capabilities that AI agents configure and use dynamically, on behalf of the user who owns the machine.

macOS has application software, system services, and daemons. It does not have a first-class concept for software whose primary role is to be a trusted intermediary between an AI agent and the operating system. Majordomo defines that category.

### 1.2 What It Does

Majordomo runs persistently on macOS. It exposes the Mac's capabilities — calendar, files, smart home, research, communication, physical devices — through a standard protocol interface (MCP). Any AI agent that can speak that protocol can use those capabilities, subject to the user's explicit permission for each capability class.

The agent is the application. Majordomo is the runtime.

### 1.3 Guiding Principles

**ISC License.** Majordomo is open source under the ISC License. Anyone may use, modify, and distribute it. The source is the specification. There is no enterprise version, no cloud dependency, no telemetry. The name "Majordomo" is used for this open source project; any commercial use is the user's own business.

**Apple frameworks first.** When Apple provides a framework for a capability, use it. Before evaluating any third-party library or external API, the question is: *does Apple have this?* If yes, that is the answer. Performance on Apple Silicon, privacy guarantees, entitlement consistency, and longevity all improve when the answer is a first-party framework.

| Option | Use when |
|---|---|
| Apple first-party framework | Always, if it exists |
| Apple open-source (Swift, LLVM, ml-stable-diffusion) | No framework, but Apple maintains it |
| Swift Package (compiled in) | No Apple option; must be open-source, auditable, ISC/MIT/Apache-compatible |
| External API call (user-permissioned) | Last resort; explicit user consent per domain |

**Zero additional installs.** Majordomo is a single `.app` download. Every capability is compiled into the app binary. No npm, no pip, no Homebrew formula, no sidecar processes for the user to manage. All code is Swift.

**Deterministic code by default.** Every capability that can be implemented as deterministic code should be. Automations run on a scheduler. Matter commands speak a protocol. Solar times come from WeatherKit. Image resizing runs in Core Image. These features work consistently, without variance, without an AI model present. AI is reserved for what only AI can do: understanding natural language, making judgment calls, synthesizing context, generating content.

**Honest non-determinism.** When a feature requires an AI model, it is labeled as such in the UI. The user knows which features are deterministic code and which are AI-powered. AI-powered features may produce different results with different models, different context, or different points in time. This is not a defect — it is the nature of the technology. Majordomo does not pretend otherwise.

**Accessibility is first-class.** Accessibility is a design constraint, not a compliance checkbox. VoiceOver, Voice Control, Switch Control, keyboard navigation, Dynamic Type, Reduced Motion, and High Contrast are tested as primary paths, not afterthoughts. Any feature that cannot be used by a VoiceOver user is not finished.

**Graceful degradation.** No single failure — model unavailability, plugin error, device timeout, permission not yet granted — should halt the system or strand the user. Deterministic features continue running without the AI. Physical actions that fail are logged and reported. Missing permissions produce manual instructions, not errors.

**Security is the user's responsibility.** Majordomo ships with sane defaults, warns once when a configuration creates risk, and documents best practices. It does not enforce security beyond that. What the agent can do, a compromised agent can do. This is disclosed clearly.

**Model choice is the user's.** The MCP interface is model-agnostic. The user chooses and trusts their own AI model. Majordomo does not favor any provider.

### 1.4 What This Spec Is

This document is the Technical Requirements Document for Majordomo. It uses a design metaphor — the computer from a certain long-running science fiction franchise — as an internal compass for what the system should feel like when it's working well. That metaphor exists in this document. It does not appear in the product, in code comments, in UI strings, or in user-facing documentation. The product stands on its own terms.

---
The app serves two audiences simultaneously:

- **End users** (including non-technical users) who need to understand and control what their AI agent can do on their Mac and in their home.
- **Developers and power users** who want a reliable, extensible macOS automation server they can extend via plugins, API integrations, and Shortcuts.

---

## 2. Product Identity

| Attribute | Value |
|---|---|
| App name | Majordomo |
| Bundle ID | `app.majordomo` |
| Homebrew cask | `majordomo` |
| Default port | `3742` |
| MCP endpoint | `http://127.0.0.1:<port>/mcp` |
| OpenAI endpoint | `http://127.0.0.1:<port>/openai` |
| OpenAPI spec | `http://127.0.0.1:<port>/openapi.json` |
| CLI binary | `/usr/local/bin/majordomo` |
| Minimum macOS | 26.0 (Tahoe) |
| Distribution | Developer ID + Notarization (not Mac App Store) |

---

## 3. Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                       Majordomo.app                          │
│                                                              │
│  ┌──────────────────┐   ┌────────────────────────────────┐  │
│  │   SwiftUI Window │   │   Interface Layer              │  │
│  │   (Permissions,  │   │   127.0.0.1:<port>             │  │
│  │    Scripts,      │   │                                │  │
│  │    Connections,  │   │   /mcp        MCP 2025-03-26   │  │
│  │    Plugins)      │   │   /openai     OpenAI tool fmt  │  │
│  └──────────────────┘   │   /openapi.json  Discovery     │  │
│                         │   stdin/stdout  CLI adapter    │  │
│                         └───────────────┬────────────────┘  │
│                                         │                   │
│  ┌──────────────────────────────────────▼───────────────┐   │
│  │                   Tool Registry                      │   │
│  │   Built-in tools + Plugin tools                      │   │
│  │   Single source of truth for all interfaces          │   │
│  └──┬──────────┬──────────┬──────────┬──────────────────┘   │
│     │          │          │          │                       │
│  Native    EventKit   NSApple-   Process                     │
│  Fwks      Contacts   Script     (shortcuts,                 │
│  AXUIEl.   CoreAudio  (Mail,      plugin shells)             │
│  NSMeta    MusicKit   Messages,                              │
│  SCKit     NSPaste-   Safari)                                │
│            board                                             │
│                                                              │
│  ┌───────────────────────────────────────────────────────┐  │
│  │              App Intents (Siri Bridge)                │  │
│  └───────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────┘
         ▲              ▲               ▲              ▲
         │ MCP          │ OpenAI fmt    │ CLI          │ App Intents
         │              │               │              │
   Claude Desktop    Ollama /        Claude Code    Siri /
   Claude Code       LM Studio       bash scripts   Shortcuts
   any MCP host      LangChain       shell pipes
                     CrewAI
                     any OAI-compat
```

### 3.1 Interface Layer Design

The Tool Registry is the single source of truth. All three protocol adapters translate to and from the same internal `ToolCall` and `ToolResult` types. Adding a new tool automatically makes it available on all three interfaces with no additional wiring.

```swift
// Internal canonical types — all interfaces speak these
struct ToolCall {
    let name: String
    let parameters: [String: JSONValue]
}

struct ToolResult {
    let content: [ContentBlock]  // text, image, or structured data
    let isError: Bool
}

// Each interface adapter implements one protocol
protocol InterfaceAdapter {
    func parseRequest(_ data: Data) throws -> [ToolCall]
    func formatResponse(_ results: [ToolResult]) -> Data
}
```

Adapters: `MCPAdapter`, `OpenAIAdapter`, `CLIAdapter`.

### 3.2 Project Structure

```
Majordomo/
├── App/
│   ├── MajordomoApp.swift
│   └── AppDelegate.swift
│
├── Server/
│   ├── InterfaceServer.swift       # HTTP listener, routes to adapters
│   ├── MCPAdapter.swift            # MCP 2025-03-26 protocol
│   ├── OpenAIAdapter.swift         # OpenAI function calling format
│   ├── OpenAPIAdapter.swift        # /openapi.json generation
│   └── CLIAdapter.swift            # stdin/stdout JSON protocol
│
├── Tools/                          # (unchanged — all tools live here)
│   └── ...
│
├── Registry/
│   └── ToolRegistry.swift          # Single source of truth
│
├── Plugins/
│   └── ...
│
├── Prompts/
│   └── ...
│
├── Intents/
│   └── ...
│
├── Permissions/
│   └── ...
│
└── UI/
    └── ...
```

---

│
├── Server/
│   ├── MCPServer.swift             # HTTP listener (Network.framework)
│   ├── MCPRouter.swift             # JSON-RPC method dispatch
│   ├── MCPSession.swift            # Per-client session
│   └── ToolRegistry.swift          # Registers all tools + prompts
│
├── Tools/
│   ├── SystemTools.swift           # volume, brightness, sleep, say, screenshot
│   ├── FileTools.swift             # Spotlight (NSMetadataQuery), mdls
│   ├── ClipboardTools.swift        # NSPasteboard
│   ├── CalendarTools.swift         # EventKit
│   ├── ReminderTools.swift         # EventKit
│   ├── ContactsTools.swift         # Contacts.framework
│   ├── NotificationTools.swift     # UNUserNotificationCenter
│   ├── MusicTools.swift            # MusicKit
│   ├── AppTools.swift              # NSWorkspace
│   ├── AccessibilityTools.swift    # AXUIElement
│   ├── ShortcutsTools.swift        # Process → `shortcuts` CLI
│   └── ScriptTools.swift           # NSAppleScript (Mail, Messages, Safari)
│
├── Prompts/
│   └── MacOSCoworkerPrompt.swift   # "Good Coworker" MCP prompt resource
│
├── Intents/
│   ├── RunAssistantTaskIntent.swift
│   ├── RunMCPToolIntent.swift
│   └── GetStatusIntent.swift
│
├── Permissions/
│   ├── PermissionManager.swift     # TCC status + request logic
│   └── PermissionModel.swift       # Permission data model
│
└── UI/
    ├── ContentView.swift           # Single window root
    ├── PermissionDashboard.swift   # Main permissions list
    ├── PermissionRow.swift         # Expandable row component
    └── ServerStatusBar.swift       # Running/stopped strip
```

---

## 4. MCP Server Specification

### 4.1 Transport

Majordomo uses **Streamable HTTP** transport (stateless JSON) on `localhost:3742`.

- Endpoint: `POST http://localhost:3742/mcp`
- Content-Type: `application/json`
- No authentication on localhost (loopback only — not exposed to network interfaces)
- Clients register in `claude_desktop_config.json` as a remote URL server:

```json
{
  "mcpServers": {
    "majordomo": {
      "url": "http://localhost:3742/mcp"
    }
  }
}
```

### 4.2 MCP Protocol Version

Target: **MCP 2025-03-26** (current stable).

Supported methods:
- `initialize`
- `tools/list`
- `tools/call`
- `prompts/list`
- `prompts/get`
- `resources/list` *(phase 2)*

### 4.3 Tool Annotations

Every tool declares the following MCP annotations:

| Annotation | Meaning |
|---|---|
| `readOnlyHint` | Tool makes no changes to system state |
| `destructiveHint` | Tool performs an irreversible action |
| `idempotentHint` | Repeated calls produce the same result |
| `openWorldHint` | Tool may trigger side effects outside the Mac |

---

## 5. OpenAI Function Calling Interface

### 5.1 Purpose

The OpenAI adapter exposes Majordomo's full tool inventory in the OpenAI function calling format. Any agent that can call an OpenAI-compatible API — including local models via Ollama and LM Studio, LangChain, CrewAI, and any custom agent that speaks the OpenAI chat completions spec — can use Majordomo without MCP support.

### 5.2 Endpoint

```
POST http://127.0.0.1:<port>/openai
Content-Type: application/json
```

The request and response mirror OpenAI's `/v1/chat/completions` format with `tools` support. Majordomo does not generate completions — it only handles `tool_calls` extracted from the agent's request.

### 5.3 Tool Discovery

```
GET http://127.0.0.1:<port>/openai/tools
```

Returns the full tool list in OpenAI function schema format:

```json
[
  {
    "type": "function",
    "function": {
      "name": "calendar_list_events",
      "description": "List calendar events for a given date range.",
      "parameters": {
        "type": "object",
        "properties": {
          "range": {
            "type": "string",
            "enum": ["today", "week", "month"],
            "description": "The time range to query."
          }
        },
        "required": ["range"]
      }
    }
  }
]
```

### 5.4 Tool Execution Request

The agent sends a standard OpenAI `tool_calls` array. Majordomo executes each call and returns `tool` role messages:

```json
// Request — agent sends tool_calls
{
  "tool_calls": [
    {
      "id": "call_abc123",
      "type": "function",
      "function": {
        "name": "calendar_list_events",
        "arguments": "{\"range\": \"today\"}"
      }
    }
  ]
}

// Response — Majordomo returns results
{
  "tool_results": [
    {
      "tool_call_id": "call_abc123",
      "role": "tool",
      "content": "9:00 AM — Standup (30 min)\n2:00 PM — Design review (1 hr)"
    }
  ]
}
```

### 5.5 OpenAPI Spec

```
GET http://127.0.0.1:<port>/openapi.json
```

Returns a complete OpenAPI 3.1 spec describing all tool endpoints. This enables:
- Auto-configuration in frameworks that support OpenAPI-based tool discovery
- Documentation generation
- Testing via tools like Postman or Insomnia

The spec is generated dynamically from the Tool Registry, so plugins are included automatically.

### 5.6 Ollama / LM Studio Configuration

For a local model running via Ollama:

```python
import ollama

# Fetch tools from Majordomo
tools = requests.get("http://127.0.0.1:3742/openai/tools").json()

response = ollama.chat(
    model="llama3.2",
    messages=[{"role": "user", "content": "What's on my calendar today?"}],
    tools=tools
)

# Execute tool calls via Majordomo
if response.message.tool_calls:
    result = requests.post("http://127.0.0.1:3742/openai", json={
        "tool_calls": response.message.tool_calls
    })
```

### 5.7 Automatic Local Fallback

Majordomo detects whether Ollama is running on `http://localhost:11434` at launch and on a 60-second interval. This status is reflected in the AI status element of the server strip.

When the primary AI client (Claude Desktop, Claude Code, or any configured MCP client) has had no tool calls for more than 5 minutes and Ollama is available, Majordomo displays a notification:

> *"Your AI hasn't been in touch. Ollama is running locally — you can use it as a fallback. [Use Ollama] [Dismiss]"*

This is not automatic — the user explicitly switches. The distinction between models matters and shouldn't be obscured. The status strip updates to show `◉ Ollama (llama3.2) · local` when the local model is active.

For purely mechanical automations (scheduled Matter commands, script runs, solar triggers) that don't require AI reasoning, Majordomo continues executing them regardless of AI availability. The Brief panel notes: *"Your AI wasn't reachable. Scheduled automations ran normally."*

---

## 6. CLI Interface

### 6.1 Purpose

The CLI interface is a thin binary installed at `/usr/local/bin/majordomo` that communicates with the running Majordomo.app via the port file. It makes every tool available to shell scripts, Claude Code's bash tool, terminal-based agents, and anything else that can call a subprocess.

The CLI requires Majordomo.app to be running. If it isn't, the binary prints a clear error and exits with code 1.

### 6.2 Installation

Majordomo installs the CLI binary on first launch (with a one-time prompt) and removes it when the app is uninstalled. Homebrew cask users get it automatically via `caveats`.

### 6.3 Usage

**List available tools:**
```bash
majordomo tools
```

**Call a tool with JSON parameters:**
```bash
majordomo run calendar_list_events '{"range": "today"}'
```

**Pipe output:**
```bash
majordomo run spotlight_search '{"query": "invoice"}' | jq '.results[0].path'
```

**Chain tools in a shell script:**
```bash
#!/bin/bash
AGENDA=$(majordomo run calendar_list_events '{"range": "today"}')
REMINDERS=$(majordomo run reminders_list '{"due": "today"}')
echo -e "$AGENDA\n\n$REMINDERS" | majordomo run clipboard_set '{"text": "-"}'
# Note: clipboard_set reads the piped value when text is "-"
```

**Get tool schema:**
```bash
majordomo schema calendar_list_events
```

**Check server status:**
```bash
majordomo status
# → Running on port 3742 · 2 clients connected
```

### 6.4 Output Format

By default, output is plain text — the same content field returned by the tool. For structured data, pass `--json`:

```bash
majordomo run contacts_search '{"query": "Sarah"}' --json
# → {"contacts": [{"name": "Sarah Chen", "email": "..."}]}
```

Exit codes follow UNIX conventions: `0` for success, `1` for tool error, `2` for usage error, `3` for server not running.

### 6.5 Claude Code Integration

Claude Code can use Majordomo tools directly via its bash tool without any MCP configuration:

```
User: What's on my calendar this week?

Claude: [bash] majordomo run calendar_list_events '{"range": "week"}'
```

This path has no MCP overhead, no session management, no JSON-RPC — just a subprocess call. For simple tool invocations from Claude Code, it's the lowest-friction option.

### 6.6 Security

The CLI binary communicates with Majordomo.app over the loopback interface, reading the port from the port file. It does not accept network connections, does not expose a server, and cannot be used to bypass the permissions model — every tool call still goes through the same permission checks as MCP and OpenAI format calls.

---

## 7. Deterministic vs. AI-Powered Features

### 7.1 The Distinction

Majordomo features fall into two categories. The UI labels both honestly.

**Deterministic** — implemented as code. Runs consistently, produces the same output for the same input, works without an AI model present. Auditable. Testable. Reliable.

**AI-powered** — requires a language model. Output varies with the model, the context, and the phrasing of the request. May produce different results on different runs. This is not a defect — it is the nature of language model inference. The user knows.

### 7.2 Feature Classification

| Feature | Deterministic ✦ or AI-powered ✧ | Works without AI |
|---|---|---|
| Time-based automations | ✦ SMAppService scheduler | ✅ |
| Solar-based automations | ✦ WeatherKit sun events | ✅ |
| Matter device control | ✦ Matter protocol | ✅ |
| Saved script execution | ✦ Tool call replay | ✅ |
| Image preparation (resize, convert) | ✦ Core Image | ✅ |
| Language detection | ✦ NLLanguageRecognizer | ✅ |
| Translation | ✦ Translation.framework | ✅ |
| Camera change detection | ✦ Pixel diff threshold | ✅ |
| IVR navigation (documented skill) | ✦ DTMF + phrase matching | ✅ |
| Scheduled brief delivery | ✦ SMAppService + brief_deliver | ✅ |
| Natural language understanding | ✧ Language model | ❌ |
| Socratic questioning | ✧ Language model | ❌ |
| Email drafting | ✧ Language model | ❌ |
| Brief composition | ✧ Language model | ❌ |
| Skill creation from observation | ✧ Language model | ❌ |
| Disambiguation of ambiguous requests | ✧ Language model | ❌ |
| Image generation | ✧ ml-stable-diffusion / cloud | ❌ / ❌ |

### 7.3 UI Treatment

Every user-facing feature that is AI-powered carries a consistent indicator:

**In automations:** a subtle `✧ AI` badge on any automation whose trigger or action required language model judgment to create (the automation itself runs deterministically once created).

**In the Permissions tab:** permission rows for AI-powered capabilities include:
> *"This feature requires an AI model. Results may vary."*

**In the Brief panel:** the brief card header shows `✧ AI · Claude` (or the active model name).

**In Skills:** skills with `agent_can_automate: full` are labeled `✦ Runs automatically`. Skills with `agent_can_automate: partial` or `manual` are labeled `✧ AI-guided` — meaning the agent reads the skill and advises, but execution involves judgment.

**In error states:** when the AI is unavailable, AI-powered features show:
> *"✧ Requires AI · Your AI isn't reachable right now."*

Deterministic features show nothing — they simply run.

### 7.4 Non-Determinism Disclosure

The first time a user enables an AI-powered capability, Majordomo displays a one-time disclosure:

> **About AI-powered features**
>
> Some features in Majordomo use an AI model to understand your requests and make judgment calls. AI models can produce different results with different phrasing, different context, or different models.
>
> Majordomo shows ✧ on features that use AI, so you always know what's code and what's judgment.
>
> The AI you use is your choice. Majordomo works with any compatible model.

This appears once, is permanently dismissable, and is available again under Settings → About AI Features.

---

## 8. Tool Inventory



### 7.1 System

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `system_get_info` | `sw_vers`, `sysctl` | ✅ | ❌ |
| `system_get_volume` | CoreAudio | ✅ | ❌ |
| `system_set_volume` | CoreAudio | ❌ | ❌ |
| `system_get_brightness` | IOKit | ✅ | ❌ |
| `system_set_brightness` | IOKit | ❌ | ❌ |
| `system_sleep` | `IOPMSleepSystem` | ❌ | ❌ |
| `system_say` | `NSSpeechSynthesizer` | ❌ | ❌ |
| `system_screenshot` | ScreenCaptureKit | ✅ | ❌ |
| `system_notify` | UNUserNotificationCenter | ❌ | ❌ |
| `system_caffeinate` | `IOPMAssertionCreateWithName` | ❌ | ❌ |

### 5.2 Files & Search

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `spotlight_search` | NSMetadataQuery | ✅ | ❌ |
| `file_get_metadata` | `MDItemCreate` | ✅ | ❌ |
| `finder_reveal` | NSWorkspace | ❌ | ❌ |
| `finder_open` | NSWorkspace | ❌ | ❌ |
| `file_move_to_trash` | FileManager | ❌ | ✅ |

### 5.3 Clipboard

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `clipboard_get` | NSPasteboard | ✅ | ❌ |
| `clipboard_set` | NSPasteboard | ❌ | ❌ |

### 5.4 Applications

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `app_list_running` | NSWorkspace | ✅ | ❌ |
| `app_launch` | NSWorkspace | ❌ | ❌ |
| `app_quit` | NSAppleScript | ❌ | ✅ |
| `app_get_frontmost` | NSWorkspace | ✅ | ❌ |

### 5.5 Calendar & Reminders

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `calendar_list_events` | EventKit | ✅ | ❌ |
| `calendar_create_event` | EventKit | ❌ | ❌ |
| `reminders_list` | EventKit | ✅ | ❌ |
| `reminders_create` | EventKit | ❌ | ❌ |

### 5.6 Contacts

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `contacts_search` | Contacts.framework | ✅ | ❌ |
| `contacts_get` | Contacts.framework | ✅ | ❌ |

### 5.7 Music

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `music_now_playing` | MusicKit | ✅ | ❌ |
| `music_play_pause` | MusicKit | ❌ | ❌ |
| `music_skip` | MusicKit | ❌ | ❌ |
| `music_set_volume` | MusicKit | ❌ | ❌ |

### 5.8 Accessibility / UI Automation

| Tool | Framework | readOnly | destructive |
|---|---|---|---|
| `ui_get_frontmost_window` | AXUIElement | ✅ | ❌ |
| `ui_click` | AXUIElement | ❌ | ✅ |
| `ui_keystroke` | CGEvent | ❌ | ✅ |
| `ui_get_menu_items` | AXUIElement | ✅ | ❌ |
| `ui_click_menu_item` | AXUIElement | ❌ | ✅ |

### 5.9 Shortcuts

| Tool | Mechanism | readOnly | destructive |
|---|---|---|---|
| `shortcuts_list` | `shortcuts list` | ✅ | ❌ |
| `shortcuts_run` | `shortcuts run "<name>"` | ❌ | context-dependent |
| `shortcuts_run_with_input` | stdin pipe | ❌ | context-dependent |

### 5.10 AppleScript Layer (Mail, Messages, Safari)

| Tool | App | readOnly | destructive | openWorld |
|---|---|---|---|---|
| `mail_list_messages` | Mail | ✅ | ❌ | ❌ |
| `mail_search` | Mail | ✅ | ❌ | ❌ |
| `mail_send` | Mail | ❌ | ✅ | ✅ |
| `mail_create_draft` | Mail | ❌ | ❌ | ❌ |
| `messages_send` | Messages | ❌ | ✅ | ✅ |
| `safari_get_url` | Safari | ✅ | ❌ | ❌ |
| `safari_get_tabs` | Safari | ✅ | ❌ | ❌ |
| `safari_open_url` | Safari | ❌ | ❌ | ✅ |
| `safari_execute_js` | Safari | ❌ | context-dependent | ✅ |

---

## 6. Permission Model

### 6.1 TCC Entitlements Required

| Permission | Entitlement | Tools Gated |
|---|---|---|
| Accessibility | `com.apple.security.accessibility` | All `ui_*` tools |
| Screen Recording | `com.apple.security.screen-recording` | `system_screenshot` |
| Calendar | `NSCalendarsUsageDescription` | All `calendar_*`, `reminders_*` |
| Contacts | `NSContactsUsageDescription` | All `contacts_*` |
| Full Disk Access | (System Preferences only) | `spotlight_search` (extended), `file_*` |
| Automation – Mail | `com.apple.security.automation.apple-events` | `mail_*` |
| Automation – Messages | same | `messages_send` |
| Automation – Safari | same | `safari_*` |
| Location | `NSLocationUsageDescription` | *(phase 2)* |

### 6.2 Permission Fallback — Teach and Offer

When a tool requires a permission that hasn't been granted, Majordomo does not return an error. It returns a structured fallback response containing two things: how the user can do the task manually right now, and how to grant the permission once so the agent can handle it automatically in future.

```json
{
  "permission_required": {
    "permission": "screen_recording",
    "manual": {
      "instruction": "Press Command-Shift-4 to select an area, or Command-Shift-3 for the full screen.",
      "note": "Screenshots save to your Desktop by default."
    },
    "grant": {
      "instruction": "To let Majordomo handle this automatically:",
      "path": "System Settings → Privacy & Security → Screen Recording → Majordomo",
      "settings_url": "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
    }
  }
}
```

The agent receives this and responds accordingly — never framing it as a failure:

> "I don't have permission to take a screenshot. You can do it with Command-Shift-4 — draw a box around the area you want. If you'd like me to handle screenshots automatically going forward, you can enable that in System Settings → Privacy & Security → Screen Recording."

The grant path is mentioned once per conversation. If the user has already been told and still hasn't granted it, the agent gives only the manual instruction on subsequent calls — it doesn't repeat the grant offer.

### 6.3 Contextual Permission Requests

When the agent needs a permission it doesn't have and the task is specific enough to explain exactly why, Majordomo requests the permission in context rather than showing a generic row in the Permissions tab. The agent uses the task at hand to make the request concrete:

> "I'd like to email your insurance company about claim #4821. I may also email them if there are follow-up questions on this claim. You can:
> - **Do it yourself** — I'll draft the email and you send it
> - **Allow for this claim** — I can email regarding claim #4821 only
> - **Always allow insurance correspondence** — I can email insurance companies on your behalf going forward"

This maps to three grant scopes:

| Scope | What it grants | When to use |
|---|---|---|
| `once` | This specific action | Default for first-time or sensitive requests |
| `scoped` | This task/entity (claim, contact, device) | When the context is bounded |
| `always` | Full permission class | When the user has demonstrated trust over time |

The granularity of the request matches the specificity of the context. A vague task gets a vague permission request. A specific task — "email claim #4821 follow-up" — gets a specific, bounded grant offer.

Generic permissions in the Permissions tab remain for capabilities the user proactively wants to enable before any specific task arises.

**Per-permission manual fallbacks:**

| Permission | Manual instruction |
|---|---|
| Screen Recording | Command-Shift-4 (region) or Command-Shift-3 (full screen) |
| Accessibility | Step-by-step: "Click the [button name] in [app name]" |
| Calendar | "Open Calendar.app and check [date/event]" |
| Contacts | "Open Contacts.app and search for [name]" |
| Full Disk Access | "Open Finder, navigate to [path]" |
| Camera | "Take a photo with your iPhone or open Photo Booth" |
| Microphone | Push-to-talk in Voice Memos, or speak the task aloud |
| Mail automation | "In Mail, choose File → New Message" |

The manual instruction is task-specific, not generic. "Open System Settings" is not a manual fallback. "Click the Submit button in the top-right of the Safari window" is.

### 6.3 Tool Failure — Bug Report Prompt

When a tool fails for reasons other than missing permissions (unexpected errors, framework exceptions, malformed responses), the error response includes a `bugReport` field. The agent is expected to surface this to the user and offer to draft a GitHub issue.

```json
{
  "error": {
    "code": -32603,
    "message": "calendar_create_event failed: EKErrorDomain code 3 — calendar is read-only.",
    "data": {
      "tool": "calendar_create_event",
      "errorDomain": "EKErrorDomain",
      "errorCode": 3,
      "majordomo_version": "1.0.0",
      "macos_version": "26.0",
      "bugReport": {
        "suggested": true,
        "repo": "your-handle/majordomo-mcp",
        "title": "calendar_create_event fails with EKErrorDomain code 3 on macOS 26",
        "body_template": "## What happened\n<!-- Describe what you were trying to do -->\n\n## Error\n```\nEKErrorDomain code 3 — calendar is read-only.\n```\n\n## Environment\n- Majordomo version: 1.0.0\n- macOS: 26.0\n\n## Steps to reproduce\n<!-- What did you ask your AI agent to do? -->"
      }
    }
  }
}
```

The agent uses `bug_report_open` (see Section 9) to open a pre-filled GitHub new issue page. The user only needs a GitHub account — no token, no OAuth, no API key.

### 6.4 Permission Polling

`PermissionManager` polls TCC status every 5 seconds while the app is frontmost, and on `NSWorkspace.didActivateApplicationNotification`. The UI updates reactively via `@Published` properties.

---

## 7. Siri Integration via App Intents

Majordomo exposes macOS capabilities to Siri using the **App Intents** framework (macOS 13+). This does not hardcode any AI model — it routes through Majordomo's local MCP server, which any connected agent can respond to.

### 7.1 How It Works

```
User: "Hey Siri, use Majordomo to check my calendar for today"
         │
         ▼
Siri invokes RunAssistantTaskIntent(task: "check my calendar for today")
         │
         ▼
Majordomo routes task to connected MCP client via callback
         │
         ▼
MCP client (e.g. Claude Desktop) calls calendar_list_events
         │
         ▼
Result returned to Siri as spoken/displayed response
```

**Constraint:** Siri responses must be synchronous and return within ~10 seconds. Long-running tasks should return a summary, not stream.

### 7.2 Defined App Intents

```swift
// Generic natural language task — routes to whatever agent is connected
struct RunAssistantTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask your AI assistant"
    @Parameter(title: "Task") var task: String
}

// Invoke a named MCP tool directly from Siri or Shortcuts
struct RunMCPToolIntent: AppIntent {
    static var title: LocalizedStringResource = "Run a Majordomo tool"
    @Parameter(title: "Tool name") var toolName: String
    @Parameter(title: "Parameters (JSON)", default: "{}") var parametersJSON: String
}

// Status check — "Hey Siri, is Majordomo running?"
struct GetMajordomoStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Majordomo status"
}
```

### 7.3 Shortcuts Exposure

All three intents appear automatically in the Shortcuts app, enabling power users to build multi-step workflows that combine Majordomo tools with other Mac automation.

---

## 8. The macOS Coworker Prompt

Majordomo exposes a built-in **MCP Prompt resource** named `macos-coworker`. Any connected agent can fetch this prompt and adopt it as a system prompt, establishing behavioral norms for operating on macOS.

### 8.1 Fetching the Prompt

```json
// Request
{ "method": "prompts/get", "params": { "name": "macos-coworker" } }

// Response
{
  "description": "Guidelines for AI agents operating on macOS via Majordomo",
  "messages": [
    { "role": "user", "content": { "type": "text", "text": "<prompt text>" } }
  ]
}
```

### 8.2 Prompt Content — Draft

```
You are operating on a user's Mac via Majordomo. Follow these guidelines 
to be a considerate and trustworthy coworker.

UNDERSTAND BEFORE ACTING — DEFAULT MODE
Majordomo is Socratic by default. Before completing any non-trivial request,
ask the single most clarifying question — the one whose answer most changes
what you would do. Do not ask multiple questions. Do not ask if the task is
clear and unambiguous. The goal is to act on what the user actually wants,
not the first interpretation of what they said.

Examples of when to ask:
- "Close my windows at sunset" → "Every day, or just today?"
- "Email John about the meeting" → "What's the key thing you want him to know?"
- "Clean the living room" → "Vacuum only, or mop too?"

Examples of when NOT to ask:
- "Turn off the kitchen light" → just do it
- "What's on my calendar tomorrow?" → just answer
- "Call Chase" → call Chase

The threshold is: would the answer meaningfully change what you do? If yes, ask.
If you can make a reasonable assumption and it's easy to undo, act and state
your assumption: "I'll close all windows in the Kitchen — let me know if 
you meant a different room."

BEFORE ACTING
- For any action that sends a message, creates a calendar event, or moves a file,
  state what you are about to do and wait for confirmation unless the user has 
  explicitly told you to proceed without asking.
- For destructive or irreversible actions (sending email, deleting files, quitting
  apps), always confirm — even if the user said "just do it."

WORKING WITH APPS
- Never force-quit an application. Use app_quit, which respects unsaved documents.
- Before quitting an app, check whether it has unsaved changes if the tool supports it.
- Do not open more applications or windows than the task requires.
- Restore the user's focused app when you are done if you changed focus.

WORKING WITH FILES
- Prefer file_move_to_trash over permanent deletion.
- Do not read files that were not part of the user's request.
- When searching with spotlight_search, use the most specific query possible.

WORKING WITH COMMUNICATION
- mail_send and messages_send are irreversible. Treat them as permanent.
- Always show the user a draft before sending unless they have explicitly 
  pre-authorized sending for this session.
- Never send to additional recipients beyond those the user specified.

REPORTING
- After completing a multi-step task, briefly summarize what you did.
- If a tool fails, explain what happened and what state the system is in.
- If you could not complete a task, say so clearly rather than doing something adjacent.

MINIMAL FOOTPRINT
- Do not retain file contents, message contents, or contact details beyond 
  what is needed to complete the immediate task.
- Do not take screenshots unless the task explicitly requires them.
- Do not access the clipboard unless asked.

WHEN A PERMISSION IS MISSING
- Never treat a missing permission as a failure or dead end. The user may 
  have denied it intentionally. Honor that.
- Always lead with the manual path: tell the user exactly how to do the task 
  themselves, step by step, as if you were coaching them.
- Then mention the grant path once: tell them where to enable the permission 
  and what it will unlock. Be specific — name the exact pane in System Settings.
- Never mention the grant path more than once per conversation. If you have 
  already offered it and they have not acted on it, give only the manual 
  instruction on subsequent requests. Do not nag.
- Frame it as an option, not a requirement: "If you'd like me to handle 
  this automatically in future, you can enable Screen Recording in 
  System Settings → Privacy & Security." Not: "You need to grant permission."
- The goal is: user accomplishes their task either way.
```

### 8.3 Versioning

The prompt is versioned. `prompts/list` returns:

```json
{
  "name": "macos-coworker",
  "description": "Guidelines for AI agents operating on macOS via Majordomo",
  "version": "1.0"
}
```

Prompt content may be updated in future app versions. The version string allows clients to detect changes.

---

## 9. UI Specification

### 9.1 First Launch — Onboarding

On first launch, before the main window, Majordomo presents a single onboarding flow. It does not ask for permissions. It does not explain MCP. It does one thing: gets the user to their first successful agent interaction.

**Screen 1 — What Majordomo does (15 seconds)**

A single card, no scrolling:

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│          ⚙  Majordomo                                   │
│                                                         │
│   Your AI now knows your Mac.                           │
│                                                         │
│   Ask it to check your calendar, control your home,     │
│   make a phone call, or close your windows at sunset.   │
│   You decide what it can do.                            │
│                                                         │
│              [ Get Started → ]                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Screen 2 — Connect your AI (auto-detects installed clients)**

Majordomo scans for Claude Desktop, Claude Code, and known MCP clients. If found:

```
┌─────────────────────────────────────────────────────────┐
│   Connect your AI                                       │
│                                                         │
│   ✓  Claude Desktop found                               │
│      Majordomo will add itself automatically.           │
│                                                         │
│              [ Connect Claude Desktop ]                 │
│                                                         │
│   ─── or connect manually ───                           │
│   Copy this address into your MCP client:               │
│   http://localhost:3742/mcp        [ Copy ]             │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

One click auto-patches Claude Desktop's config and relaunches it. No JSON editing.

**Screen 3 — Try it now**

```
┌─────────────────────────────────────────────────────────┐
│   Ask Claude something                                  │
│                                                         │
│   Claude Desktop is connected. Try asking:              │
│                                                         │
│   "What's on my calendar tomorrow?"                     │
│   "Close all my windows"                                │
│   "Remind me to call the dentist"                       │
│                                                         │
│   Claude will ask Majordomo for permission the          │
│   first time it tries anything new.                     │
│                                                         │
│              [ Open Claude Desktop ]                    │
│   [ I'll try it later — take me to Settings ]           │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

Done. No permission dialogs during onboarding. Permissions appear contextually when the agent first needs them — which is the right time, because the user then understands why.

**Returning users.** If Majordomo detects it has been opened before but never had a successful tool call, it offers a gentle re-entry: *"Looks like you haven't connected an AI yet. Want to try again?"*

### 9.2 Main Window

Majordomo is a single-window SwiftUI app (fixed width 640pt, non-resizable). It appears in the Dock and the standard app switcher.

**Server status strip** — always visible at the top, below the title bar:

```
● Running  ·  localhost:3742  ·  Claude Desktop  ·  ◉ Claude  12ms  ·  ☁ iCloud ✓
```

| Element | States |
|---|---|
| Server indicator | ● Running (green) / ○ Stopped (grey) |
| Port | `localhost:3742` |
| Connected client | Client name, or "No clients" |
| AI status | ◉ Model name · latency — or ⚠ Unavailable · "Using local fallback" |
| iCloud sync | ☁ ✓ (synced) / ☁ ↑ (uploading) / ☁ ⚠ (error) / hidden if iCloud not signed in |

The AI status element is tappable — opens a popover showing model name, API endpoint, last successful call, and a **Switch to local model** option if Ollama is detected on port 11434.

### 9.3 Tabs

Five tabs beneath the status strip: **Permissions · Scripts · Skills · Connections · Plugins**

### 9.4 Permissions Tab

| Section | Content |
|---|---|
| Page header | "Majordomo allows your AI agent to…" |
| High-agency section | "Acts on your behalf" — tools that take action |
| Read-only section | "Reads your information" — tools that observe |
| Footer | Link to System Settings → Privacy & Security |

### 9.5 Permission Row States

| State | Indicator | Expanded action |
|---|---|---|
| **Allowed** | Green dot | **Revoke Access** button |
| **Not Set** | Yellow dot | **Allow** button |
| **Not Allowed** | Grey dot | **"Let Majordomo do this"** → deep-links to exact System Settings pane |

The Not Allowed state shows the manual fallback beneath the button:
> *"Until then: Command-Shift-4 to capture a region."*

### 9.6 Scripts Tab

Each row: name · description · run count · last run · ▶ Run · ··· menu (Rename, View steps, Delete).

Empty state: *"Scripts appear here when your AI saves a repeated task."*

### 9.7 In-App Help

Every settings pane has a **?** button in the top-right corner. Tapping it opens a slide-in panel with a plain-English explanation of what the pane does, why it exists, and what the agent can and can't do with it. This is the user documentation — embedded, contextual, and written for non-developers.

The coworker prompt editor shows: *"This file shapes how your AI behaves on your Mac. Changes take effect immediately. If something goes wrong, tap 'Reset to Default.'"*

A **Help** menu item opens the full online documentation at `majordomo.app/docs`.

### 9.9 Menu Bar Presence

Majordomo lives in the menu bar as its primary interaction surface. The main window is the configuration surface — permissions, settings, plugins, logs. The menu bar item is where the agent is *used*.

**Menu bar icon.** The Majordomo key icon in the menu bar. Its state:
- Still key: server running, no activity
- Key turning: tool call in progress
- Key with dot: unread Brief

**Menu bar popover** (click or voice trigger):

```
┌──────────────────────────────────┐
│  🎙 Ask Majordomo…               │
│  ________________________________│
│                                  │
│  ┌ Morning Brief · 7:04 AM ─────┐│
│  │ 3 meetings · 2 reminders due ││
│  │ Kitchen shade failed (open)  ││
│  └──────────────────────────────┘│
│                                  │
│  Recent:                         │
│  ✓ Closed west windows · 6:12 PM │
│  ✓ Morning briefing · 7:04 AM    │
│  ✗ Kitchen shade · timeout       │
│                                  │
│            Open Majordomo…       │
└──────────────────────────────────┘
```

The text field accepts typed queries. The voice icon activates voice input without requiring push-to-talk. The Recent list shows the last three agent actions with status. "Open Majordomo…" opens the main window.

The popover is accessible system-wide via the menu bar — no window switching, no context disruption.

### 9.10 Ambient Context

With Screen Recording permission granted, Majordomo maintains a lightweight ambient context: which app is frontmost, the window title, and which coach is active. This context is available to the agent on every tool call — the agent doesn't need to ask what the user is doing.

```json
{
  "ambient_context": {
    "frontmost_app": "BBEdit",
    "window_title": "privacy-policy.md",
    "active_coach": "bbedit-coworker",
    "screen_recording": true
  }
}
```

"Send this to John" while a Pages document is open resolves "this" automatically. "What am I looking at?" answers with the current document. The agent's context window includes the ambient state as background — not a tool call, just known.

`context_watch` delivers ambient context via the SSE stream when the frontmost app changes, so the agent receives updates without polling.

The ambient context is never stored in logs by default — it's transient state that exists only for the duration of the active conversation.



### 9.11 Accessibility

Accessibility is a first-class design constraint per Section 1.3. Every feature is a primary path, not an afterthought. Any feature a VoiceOver user cannot complete is not finished.

**VoiceOver.** All interactive elements carry `accessibilityLabel` and `accessibilityHint`. Permission rows announce: *"Screen Recording, Not Allowed. Double-tap to expand."* Every state change is announced. The record button reads: *"Record a new skill. Double-tap to choose a recording mode."*

**Voice Control.** Every interactive element has a unique, pronounceable name. "Click Allow" resolves unambiguously on any screen. Skills and permission rows are addressable by their visible labels.

**Switch Control.** Tab bar, permission rows, skills, and recording modes have explicit Switch Control group and item configuration. Sequential navigation reaches every interactive element without gaps.

**Keyboard navigation.** Every control reachable by Tab. Expand/collapse responds to Space. Tab picker responds to arrow keys. No mouse required for any operation.

**Dynamic Type.** All text uses scaled font styles. Layouts reflow at accessibility text sizes.

**Reduced Motion.** `@Environment(\.accessibilityReduceMotion)` disables all animations.

**High Contrast.** Status indicators use color plus shape: allowed = filled circle, not-set = ring, denied = ✕.

**Accessible manual fallbacks.** Every "do it yourself" instruction includes an accessible alternative. "Press Command-Shift-4" is supplemented with the equivalent Screenshot app path for users who can't use that shortcut.

---





A badge on the Scripts tab label appears when Majordomo has detected a candidate pattern not yet saved as a script.

### 9.5 Script Detail Sheet

Tapping ··· → "View steps" opens a sheet showing the recorded tool call sequence in plain English — not raw JSON. Each step is rendered as a human-readable sentence:

```
1. Search Spotlight for "invoices"
2. Open the most recent result in Finder
3. Copy the file path to clipboard
```

A **Run** button and a **Send to Shortcuts** button appear at the bottom of the sheet.

### 9.6 Onboarding

On first launch, before the permissions dashboard, display a single onboarding screen:
- What Majordomo is (one paragraph)
- That it is not Claude-specific
- That no data leaves the Mac — all communication is local
- A "Get Started" button that opens the permissions dashboard

---


## 9. Bug Reporting

### 9.1 Philosophy

When a tool fails unexpectedly, the best person to file the bug report is the user who just experienced it — with the agent doing all the drafting work. Majordomo provides a `bug_report_open` tool that takes a pre-filled title and body and opens GitHub's new issue URL directly in the browser. The user just reviews, adds context if they want, and clicks Submit. No API token. No OAuth flow. A GitHub account is the only requirement.

### 9.2 The `bug_report_open` Tool

```swift
// Tool definition
name: "bug_report_open"
description: "Opens a pre-filled GitHub issue in the browser. Use this when a tool 
              fails unexpectedly. Draft the title and body, then call this tool — 
              the user will review and submit."
annotations:
  readOnlyHint: false
  destructiveHint: false
  openWorldHint: true   // opens browser
```

**Input schema:**

```json
{
  "title": {
    "type": "string",
    "description": "Issue title. Include the failing tool name and macOS version."
  },
  "body": {
    "type": "string", 
    "description": "Issue body in Markdown. Include: what the user was doing, the exact error, environment details, and steps to reproduce."
  }
}
```

**Implementation:**

```swift
func bugReportOpen(title: String, body: String) throws {
    let repo = "your-handle/majordomo-mcp"
    var components = URLComponents(string: "https://github.com/\(repo)/issues/new")!
    components.queryItems = [
        URLQueryItem(name: "title", value: title),
        URLQueryItem(name: "body", value: body),
    ]
    guard let url = components.url else { throw ToolError.invalidURL }
    NSWorkspace.shared.open(url)
}
```

GitHub's new issue URL accepts `title` and `body` as query parameters and pre-fills the form. Character limits are generous (body up to ~65k characters). The URL is opened with `NSWorkspace.shared.open()` — it goes to the user's default browser, where they are presumably already logged in to GitHub.

### 9.3 Agent Behavior on Tool Failure

When a tool returns an error with `bugReport.suggested: true`, the agent should:

1. Explain what failed in plain language.
2. Offer to file a bug report: *"Would you like me to draft a GitHub issue for this? You'll just need to review it and click Submit."*
3. If the user agrees, call `bug_report_open` with a well-formed title and body.
4. Confirm the browser opened and remind the user they need to be signed in to GitHub to submit.

The agent should **not** file the bug automatically — the user should review the draft before it becomes a public issue.

### 9.4 Issue Body Template

The agent should populate the body with:

```markdown
## What happened
[Agent's plain-English description of what the user was trying to do]

## Error
```
[Exact error message and error domain/code from the tool response]
```

## Environment
- Majordomo: [version from tool response]
- macOS: [version from tool response]
- AI agent: [e.g. Claude Desktop, Claude Code — agent fills this in]

## Steps to reproduce
[Agent's reconstruction of the task sequence that led to the error]

## Additional context
<!-- Anything else? Screenshots, workarounds you tried? -->
```

### 9.5 The Coworker Prompt Addition

The `macos-coworker` prompt (Section 8) includes the following guidance on bug reporting:

```
WHEN A TOOL FAILS
- If a tool returns an unexpected error (not a missing permission), tell the user 
  what failed and what you were trying to do.
- Offer to file a bug report using bug_report_open. Draft a clear title and a 
  complete body — include the error, the macOS version, the Majordomo version, 
  and a reconstruction of what led to the failure.
- Do not file the report automatically. Show the user what you've drafted and 
  ask them to confirm before opening the browser.
- A good bug title names the tool and the failure: 
  "calendar_create_event fails with EKErrorDomain code 3 on macOS 26"
```

---

## 10. Distribution

| Channel | Mechanism |
|---|---|
| Primary | Direct download from `majordomo.app` |
| Homebrew | `brew install --cask majordomo` |
| Auto-update | Sparkle framework |
| Code signing | Developer ID Application certificate |
| Notarization | `xcrun notarytool` via CI |

The app is **not submitted to the Mac App Store** due to App Sandbox incompatibility with Accessibility, Apple Events, and Full Disk Access entitlements.

---

## 11. macOS Coach

### 11.1 Purpose

Majordomo exposes a second MCP Prompt resource — `macos-coach` — that transforms the agent into a patient, adaptive instructor. It is fetched alongside `macos-coworker` when the agent detects a learning intent in the user's message.

The design principle is **andragogy**: adults learn best when instruction is immediate, practical, and builds on what they already know. The agent does not deliver curriculum — it meets the user at the moment of need and teaches just enough to move them forward with confidence.

### 11.2 Skill Signal Detection

The agent infers skill level from vocabulary, phrasing, and context. No explicit proficiency quiz is required.

| Signal | Likely level | Example |
|---|---|---|
| Functional description, no jargon | Beginner | *"how do I make everything bigger"* |
| Task name without method | Intermediate | *"how do I take a screenshot of just one window"* |
| Tool or concept name | Advanced | *"what's the fastest way to batch rename files in Finder"* |
| Architecture or code question | Developer | *"teach me how to build an app"* |

The agent adjusts language, depth, and assumed prior knowledge to match. It does not label the user's level aloud — it simply responds at the right altitude.

### 11.3 The `macos-coach` Prompt Resource

```
You are helping someone learn to use their Mac with more confidence. 
Follow these principles.

MEET THEM WHERE THEY ARE
- If the user describes what they want in plain language ("make things bigger", 
  "find that file I had open"), answer in plain language. Do not introduce 
  technical vocabulary unless the user uses it first.
- If the user uses technical terms correctly, match their register. Do not 
  over-explain to someone who already knows.
- If you are unsure of their level, ask one practical question before explaining:
  "Have you changed display settings before, or is this new territory?"

DO, THEN TEACH
- For tasks Majordomo can perform directly, do the thing first, then explain 
  what you did and where the setting lives. Completing the task builds 
  immediate confidence; the explanation anchors the learning.
- Example pattern: "I've increased the text size — you can find this any time 
  in System Settings → Displays → Text Size. Want me to walk you through it?"

SCAFFOLD COMPLEXITY
- Break multi-step tasks into the smallest pieces that feel complete on their own.
- After each step, check in before continuing: "That part's done. Ready for 
  the next step, or do you want to try it yourself from here?"
- Do not present more than three steps at once to a beginner.

USE WHAT THEY ALREADY KNOW
- Anchor new concepts to familiar ones, especially iPhone/iPad:
  "System Settings on Mac works like the Settings app on your iPhone."
  "Finder is like Files on your phone — it's where all your documents live."
- For users coming from Windows:
  "The Dock works like the Windows Taskbar."
  "Command-C and Command-V do the same thing as Ctrl-C and Ctrl-V."

BUILD CONFIDENCE, NOT DEPENDENCE
- The goal is for the user to be able to do this themselves next time.
- After completing a task, offer a one-sentence summary they can remember:
  "The short version: Command-Shift-4 lets you draw a box around anything 
  and save it as a screenshot."
- Celebrate small wins genuinely: "You just used your first keyboard shortcut."
- Do not perform tasks silently. If the user could learn something from 
  watching you do it, narrate as you go.

DEVELOPER TRACK
- When a user asks how to build something ("teach me how to build an app", 
  "how do I write a script"), assess what they already know before suggesting 
  tools: "Have you written code before, or are we starting from scratch?"
- Recommend Swift and Xcode for native Mac apps. Recommend Shortcuts for 
  automation without code.
- Offer to build a first small thing together rather than explaining in the abstract.
- Use Majordomo's own tools as live examples: "Here's a script that does what 
  Majordomo does when it reads your calendar — want to walk through it?"
```

### 11.4 Companion Tools for Teaching

These tools exist specifically to support the coaching use case. They navigate the user to relevant parts of macOS so they can see the setting they just changed, or practice the task themselves.

| Tool | Action | Teaching use |
|---|---|---|
| `settings_open` | Opens a specific System Settings pane by identifier | "Here's where I made that change" |
| `accessibility_set_text_size` | Sets system text size (pt) | Immediate result for "make it bigger" |
| `accessibility_enable_zoom` | Enables/configures screen zoom | Accessibility teaching |
| `spotlight_open` | Opens Spotlight | Teaches search as a core habit |
| `finder_open_home` | Opens Finder at the user's home folder | Orients beginners to file system |
| `shortcuts_open_gallery` | Opens the Shortcuts app gallery | Entry point for no-code automation |
| `xcode_check_installed` | Returns Xcode install status and version | Entry point for developer track |

### 11.5 `settings_open` Deep Link Map

`settings_open` accepts a pane identifier and opens it directly via `x-apple.systempreferences:` URL scheme.

| Identifier | Opens |
|---|---|
| `displays` | System Settings → Displays |
| `accessibility.display` | Accessibility → Display (text size, contrast) |
| `accessibility.zoom` | Accessibility → Zoom |
| `appearance` | Appearance (Dark/Light mode, accent color) |
| `keyboard` | Keyboard |
| `trackpad` | Trackpad |
| `privacy.accessibility` | Privacy & Security → Accessibility |
| `software-update` | General → Software Update |

### 11.6 Prompt Composition

`macos-coworker` and `macos-coach` are assembled dynamically each time a client fetches them. The composition order is:

1. Base prompt (user-edited or bundled default)
2. Each enabled plugin's `coworker.md` or `coach.md`, in installation order, labelled by plugin name

The agent fetches `macos-coach` in addition to `macos-coworker` when the user's message contains any of:

- A question about how to do something on a Mac or in a specific app
- A request to be taught or explained
- A description of a problem in non-technical terms
- A request to build, create, or learn something new

Both prompts are active simultaneously. `macos-coworker` governs how the agent acts; `macos-coach` governs how it communicates and what it knows.

---


## 12. Saved Scripts

### 12.1 Purpose

When a user repeatedly asks their agent to perform the same sequence of steps, Majordomo can record that sequence as a script and run it on demand — without invoking the AI at all. Scripts execute as a direct replay of MCP tool calls inside Majordomo. No tokens are consumed. No model is called. Execution is near-instant.

The agent's role is to detect the pattern, offer to save it, draft a name and description, and call `script_create`. After that, the script runs entirely within Majordomo.

### 12.2 Script Storage

Scripts are stored in `~/Library/Application Support/app.majordomo/scripts.json`.

Each script is a JSON object:

```json
{
  "id": "script_a3f9",
  "name": "Prepare morning briefing",
  "description": "Opens Calendar for today, checks Reminders, and copies today's agenda to the clipboard.",
  "created": "2026-04-01T08:22:00Z",
  "created_by": "agent",
  "steps": [
    {
      "tool": "calendar_list_events",
      "params": { "range": "today" }
    },
    {
      "tool": "reminders_list",
      "params": { "list": "all", "due": "today" }
    },
    {
      "tool": "clipboard_set",
      "params": { "text": "{{calendar_list_events.result}}\n\n{{reminders_list.result}}" }
    }
  ],
  "run_count": 4,
  "last_run": "2026-04-02T07:55:00Z"
}
```

Template variables (`{{tool.result}}`) allow a step to use the output of a prior step, enabling simple sequential pipelines without branching logic. For scripts requiring conditionals or loops, the agent should offer to export to Shortcuts instead.

### 12.3 Pattern Detection

Majordomo maintains a **call log** of every tool invocation, stored in `callog.json` in Application Support. Each entry records the tool name, parameters, timestamp, and session ID.

A background process runs a **sequence matcher** that identifies tool call sequences appearing 3 or more times across different sessions. When a candidate pattern is found:

1. A badge appears on the Scripts tab in the UI.
2. A new MCP resource `script_suggestions` becomes non-empty.
3. On the agent's next call to `resources/list`, it sees the suggestion and can proactively offer to save it.

The threshold of 3 is configurable in `defaults write app.majordomo scriptSuggestionThreshold`.

### 12.4 Script Management Tools

| Tool | Description | readOnly | destructive |
|---|---|---|---|
| `script_list` | Returns all saved scripts with metadata | ✅ | ❌ |
| `script_get` | Returns full detail for one script by ID | ✅ | ❌ |
| `script_run` | Executes a script by ID, returns aggregated output | ❌ | context-dependent |
| `script_create` | Saves a new script from a name, description, and steps array | ❌ | ❌ |
| `script_delete` | Removes a script by ID | ❌ | ✅ |
| `script_suggestions` | Returns detected repeated sequences not yet saved | ✅ | ❌ |
| `script_export_shortcut` | Converts a script to a `.shortcut` file and opens it in Shortcuts.app | ❌ | ❌ |

### 12.5 Agent Behavior — Offering to Script

The `macos-coach` prompt includes the following guidance:

```
RECOGNIZING REPEATED TASKS
- Before responding to any request, call script_suggestions to check whether 
  Majordomo has detected a repeated pattern in this session or prior sessions.
- If a suggestion exists that matches the current request, offer to save it 
  before executing: "I've done this sequence for you a few times now. Want me 
  to save it as a script? Future runs won't use any AI — Majordomo will just 
  replay the steps directly."
- When offering, name the script clearly and describe what it does in one sentence.
  Wait for the user to confirm before calling script_create.

CREATING A SCRIPT
- Call script_create with a short name (3–5 words), a one-sentence description,
  and the exact steps as an array of tool calls.
- After saving, confirm to the user: "Saved. You can run it from the Scripts tab 
  in Majordomo, or just ask me to run '[script name]' any time."
- Explain the token benefit plainly: "Running the script directly skips the AI 
  entirely — it's instant and free."

RUNNING A SAVED SCRIPT
- When a user asks for something that matches a saved script name or description,
  prefer script_run over re-executing the individual tools.
- Before running, state what the script will do: "I'll run your 'Morning briefing'
  script — that pulls today's calendar and reminders, then copies them to your 
  clipboard. Go ahead?"

LIMITATIONS
- Scripts run steps in sequence with no branching. If the user's task requires 
  "if X then Y", tell them this needs a Shortcut and offer script_export_shortcut.
- Scripts do not have access to real-time AI reasoning during execution. If a 
  step might need judgment (e.g., "find the most relevant file"), it cannot be 
  scripted reliably and should remain a live agent task.
```

### 12.6 Export to Shortcuts

`script_export_shortcut` converts a Majordomo script into a native macOS Shortcut by mapping each tool call to its Shortcuts equivalent action where one exists. The resulting `.shortcut` file is opened in Shortcuts.app for review before saving.

This path is offered when:
- The user wants the script to run on a schedule
- The user wants it accessible from the menu bar, Spotlight, or Siri by name
- The script requires conditional logic that Majordomo's linear executor cannot handle

---

## 13. Plugin System

### 13.1 Purpose

The built-in tool domains cover Apple's first-party apps and macOS system APIs. The plugin system extends Majordomo in two directions:

**App Plugins** (`"type": "app"`) — integrate macOS applications via AppleScript, JXA, CLI, or URL scheme.

**Endpoint Plugins** (`"type": "endpoint"`) — integrate addressable services: APIs, phone numbers, email, local network devices. See Section 19.

All plugins share the same bundle format, registry, and installation flow. The `type` field determines which runtime handles the plugin's tools.

### 13.2 Organic Discovery

Plugins are not primarily installed through the Plugins tab. They are discovered by the agent when it encounters a task it doesn't have tools for.

**Capability gap detection.** When a user requests something the agent has no tools for, the agent checks the plugin manifest cache before declining. If a matching plugin exists and the target app is installed, the agent offers to install it and complete the task.

**Registry manifest cache.** Majordomo maintains a local copy of the community registry manifest at:
```
~/Library/Application Support/app.majordomo/registry-cache.json
```

The cache is refreshed daily in the background with a single GET request — no user data sent. On first launch, the cache is populated from a bundled snapshot. The cache format is a flat array of plugin descriptors:

```json
[
  {
    "id": "com.pixelmatorteam.pixelmator.majordomo-plugin",
    "name": "Pixelmator Pro",
    "description": "Edit images, apply effects, remove backgrounds, manage layers.",
    "type": "app",
    "target_app_bundle_id": "com.pixelmatorteam.pixelmator.x",
    "target_app_name": "Pixelmator Pro",
    "capabilities": ["image-editing", "background-removal", "layers", "export"],
    "keywords": ["photo", "image", "edit", "pixelmator", "design"],
    "author": "community",
    "developer_id": "TEAM4392817",
    "developer_name": "Jane Smith",
    "signed": true,
    "installs": 847,
    "version": "1.2",
    "source_url": "https://github.com/majordomo-mcp/plugins/tree/main/apps/pixelmator-pro",
    "download_url": "https://github.com/majordomo-mcp/plugins/releases/download/pixelmator-pro-1.2/PixelmatorPro.majordomo-plugin.zip"
  }
]
```

**Available plugins shortlist.** On launch, Majordomo cross-references the registry cache with installed apps (`NSWorkspace.shared.urlForApplication(withBundleIdentifier:)` for each `target_app_bundle_id`). The result is a `available_plugins` MCP resource: plugins that could be installed right now because the target app is present. The agent checks this before any capability gap response.

### 13.3 Plugin Discovery Tools

| Tool | Description |
|---|---|
| `plugin_search` | Search registry cache by app name, capability keyword, or free text |
| `plugin_check_available` | Returns available plugins for a given app bundle ID or capability |
| `plugin_install` | Download, verify, and install a plugin — **requires explicit user permission** |
| `plugin_list_installed` | All currently installed plugins with status |

**`plugin_search` input schema:**
```json
{
  "query":      { "type": "string",  "description": "Free text, app name, or capability" },
  "app_bundle": { "type": "string",  "description": "Filter to plugins for a specific bundle ID" },
  "installed_apps_only": { "type": "boolean", "default": true,
                            "description": "Only return plugins whose target app is installed" }
}
```

`installed_apps_only` defaults to true — the agent only surfaces plugins for software the user actually has.

**`plugin_install` is an explicit permission action.** It never executes without user confirmation. The confirmation presents:
- Plugin name, description, version
- Developer name and signing status
- Install count from the registry
- What new capabilities and permissions it adds
- A link to view the full source on GitHub
- Three options: **View Source** · **Install** · **I'll do it myself**

"I'll do it myself" triggers the manual fallback: the agent explains how to accomplish the task without the plugin, using the app directly.

### 13.4 Coworker Prompt Addition

```
PLUGIN DISCOVERY
- When asked to do something for which no tools exist, do not immediately 
  decline. First call plugin_check_available with the relevant app bundle ID 
  or a capability keyword.
- If the target app is installed and a signed plugin exists, present it: 
  name, what it does, who made it, install count, source link. 
  Ask permission to install.
- Prefer plugins for installed native apps over web-based alternatives. 
  "Edit in Pixelmator Pro" is better than "upload to a web editor."
- Never install a plugin without explicit user confirmation.
- After install, check whether new permission rows need to be granted before 
  proceeding. Surface those naturally: "I'll need Accessibility permission 
  to control Pixelmator Pro — here's how to grant it."
- If the user declines installation, provide the manual path without comment.
- If no plugin exists for the task, say so clearly and explain the manual path.
```

### 13.5 Plugins Tab — Revised Role

The Plugins tab shifts from a primary installation surface to a management surface. New structure:

**Available for your apps** — plugins in the registry cache whose target app is installed but the plugin is not yet installed. Surfaced proactively so the user can pre-install before the agent asks. Each row shows: plugin name, target app, install count, signed status, brief description.

**Installed** — plugins currently active, with enable/disable toggle and ··· menu.

**Install from URL** — manual install for plugins not in the registry.

The "Browse Registry →" button opens the GitHub registry in the browser. The Plugins tab no longer requires the user to find plugins manually — it confirms and manages what the agent discovers organically.

### 13.2 Plugin Bundle Format

Plugins are directories with the `.majordomo-plugin` extension, installed to:

```
~/Library/Application Support/app.majordomo/Plugins/
```

A minimal BBEdit plugin looks like this:

```
BBEdit.majordomo-plugin/
├── manifest.json
├── tools/
│   ├── bbedit_open.js
│   ├── bbedit_get_selection.js
│   ├── bbedit_find_replace.js
│   └── bbedit_new_document.applescript
└── prompts/
    └── bbedit-coworker.md
```

### 13.3 manifest.json Schema

```json
{
  "name": "BBEdit",
  "id": "com.barebones.bbedit.majordomo-plugin",
  "version": "1.0.0",
  "author": "Your Name",
  "description": "BBEdit integration — open files, search, edit selections.",
  "homepage": "https://github.com/you/majordomo-bbedit",

  "target_app": {
    "bundle_id": "com.barebones.bbedit",
    "name": "BBEdit",
    "min_version": "14.0"
  },

  "entitlements_required": ["automation"],

  "tools": [
    {
      "name": "bbedit_open",
      "description": "Opens a file in BBEdit, optionally at a specific line.",
      "script": "tools/bbedit_open.js",
      "script_type": "jxa",
      "input_schema": {
        "type": "object",
        "properties": {
          "path": { "type": "string",  "description": "Absolute path to the file." },
          "line": { "type": "integer", "description": "Line number to navigate to." }
        },
        "required": ["path"]
      },
      "annotations": {
        "readOnlyHint": false,
        "destructiveHint": false,
        "openWorldHint": false
      }
    },
    {
      "name": "bbedit_get_selection",
      "description": "Returns the currently selected text in the frontmost BBEdit window.",
      "script": "tools/bbedit_get_selection.js",
      "script_type": "jxa",
      "input_schema": { "type": "object", "properties": {} },
      "annotations": { "readOnlyHint": true, "destructiveHint": false }
    },
    {
      "name": "bbedit_find_replace",
      "description": "Performs a find-and-replace across the current document or a folder.",
      "script": "tools/bbedit_find_replace.js",
      "script_type": "jxa",
      "input_schema": {
        "type": "object",
        "properties": {
          "find":    { "type": "string", "description": "Search string or regex." },
          "replace": { "type": "string", "description": "Replacement string." },
          "regex":   { "type": "boolean", "default": false },
          "scope":   { "type": "string", "enum": ["document", "folder"], "default": "document" }
        },
        "required": ["find", "replace"]
      },
      "annotations": { "readOnlyHint": false, "destructiveHint": true }
    }
  ],

  "prompts": [
    {
      "type": "coworker",
      "file": "prompts/coworker.md",
      "description": "Behavioral guidance for working with BBEdit safely — unsaved changes, undo history, project scope."
    },
    {
      "type": "coach",
      "name": "coding",
      "label": "Coding",
      "file": "prompts/coach-coding.md",
      "description": "Best practices for code editing — grep patterns, multi-file workflows, regex, shell integration.",
      "default": true
    },
    {
      "type": "coach",
      "name": "writing",
      "label": "Creative Writing",
      "file": "prompts/coach-writing.md",
      "description": "Best practices for long-form prose — structure, revision workflow, word count targets, distraction-free editing."
    }
  ]
}
```

### 13.4 Script Execution

Plugin scripts are executed by Majordomo's script runner, not by the MCP client.

| `script_type` | Runtime | Use when |
|---|---|---|
| `jxa` | `OSAScript` with JavaScript dialect | App has a scriptable dictionary, need structured return values |
| `applescript` | `OSAScript` with AppleScript dialect | Legacy dictionaries, simpler interactions |
| `shell` | `Process` with restricted environment | CLI tools (`bbedit` CLI, `git`, etc.) |
| `url` | `NSWorkspace.open(_:)` | Apps with URL scheme automation |

**Input passing.** The tool's `input_schema` parameters are serialised to JSON and passed to the script as a single argument string. The script is responsible for parsing it.

**JXA example — `bbedit_open.js`:**

```javascript
function run(argv) {
  const input = JSON.parse(argv[0]);
  const app = Application("BBEdit");
  app.activate();
  const doc = app.open(Path(input.path));
  if (input.line) {
    doc.selection.characterRange = [0, 0];
    app.scrollToLine(input.line, { in: doc });
  }
  return JSON.stringify({ opened: input.path, line: input.line || null });
}
```

**Output.** Scripts must return a JSON string. Majordomo parses this and includes it in the MCP tool response as structured content.

### 13.5 Agentic Instructions

Each plugin contributes to two prompt channels via Markdown files in the bundle, editable by the user.

| Prompt type | File(s) | Merged into | Purpose |
|---|---|---|---|
| `coworker` | `prompts/coworker.md` | `macos-coworker` | Behavioral constraints specific to this app |
| `coach` | `prompts/coach-<name>.md` | `macos-coach` | Domain expertise — one file per coaching context |

Neither is required. A plugin can provide tools only, or any combination.

**Multiple coaches per plugin.** A plugin may declare any number of named `coach` entries. Each has a machine-readable `name`, a human-readable `label`, and a `default` flag. Exactly one coach is active at a time per plugin. The active coach is included in prompt composition; inactive coaches are excluded.

```
BBEdit.majordomo-plugin/
├── manifest.json
├── tools/
│   └── ...
└── prompts/
    ├── coworker.md
    ├── coach-coding.md          ← default
    └── coach-writing.md
```

**Coach selection — three mechanisms:**

1. **Manual** — the user picks the active coach from the Plugins tab via a segmented control or dropdown on the plugin row. Persisted in `UserDefaults`.

2. **Agent-driven** — the agent calls `plugin_set_coach` to switch context mid-session based on what it detects in the conversation. A user who says "help me outline my novel" while BBEdit is open is signaling a writing context; an agent that recognises this and switches coaches before responding is meaningfully more useful.

3. **Automatic on file type** — if the plugin declares `context_hints`, Majordomo can switch coaches automatically when the frontmost BBEdit document changes file extension:

```json
"context_hints": {
  "coding":  { "extensions": ["swift", "py", "js", "ts", "rb", "sh"] },
  "writing": { "extensions": ["md", "txt", "fountain", "rtf"] }
}
```

Automatic switching is off by default. The user opts in per-plugin in Settings.

---

**`plugin_set_coach` tool**

```swift
name: "plugin_set_coach"
description: "Switch the active coaching context for a plugin. Call this when 
              the user's intent clearly matches a different coach than the current 
              one. State what you're switching to and why before calling."
annotations:
  readOnlyHint: false
  destructiveHint: false
```

Input schema:
```json
{
  "plugin_id": { "type": "string" },
  "coach_name": { "type": "string" }
}
```

The agent should narrate the switch: *"You're working on prose, so I'm switching to BBEdit's Creative Writing coach."* This keeps the user in control even when the agent drives the change.

---

**Example: BBEdit plugin — `coach-coding.md`**

```markdown
## BBEdit for Coding

NAVIGATION
- Use bbedit_find_replace with regex for multi-file refactors. 
  BBEdit's grep is PCRE — use (?:...) for non-capturing groups.
- Use bbedit_open with a line number to jump directly to an error location.
- Open the Differences window to compare before and after a bulk change.

WORKFLOW
- BBEdit projects (.bbprojectd) scope Find Differences and multi-file search.
  Always confirm the project root before running a folder-wide operation.
- Prefer bbedit_get_selection to read only the relevant code, not the 
  entire file — context windows are finite.
- BBEdit integrates with git via the sidebar. Do not use bbedit tools to 
  manage git state — use dedicated git tools instead.

SHELL INTEGRATION
- The `bbedit` CLI accepts stdin: pipe command output directly into a new 
  document with `command | bbedit`.
- Use #! shebang lines — BBEdit detects language from the shebang and 
  applies the right syntax colouring and folding.
```

---

**Example: BBEdit plugin — `coach-writing.md`**

```markdown
## BBEdit for Writing

ENVIRONMENT
- Use Focus Mode (View → Enter Focus Mode) to hide the project sidebar 
  and toolbar. Ask the user if they want this before a long writing session.
- Set the font to a proportional face for prose — BBEdit respects per-document 
  font settings. Suggest this if the user is writing long-form.
- Soft wrap to window width. Hard wraps at 80 characters interrupt prose flow.

STRUCTURE
- BBEdit's #Mark comments create a document outline in the function popup.
  Use ## Chapter Title and ### Section to build a navigable structure.
- Use bbedit_get_selection to read the current paragraph before suggesting 
  a revision — never rewrite more than the user asked you to touch.

REVISION WORKFLOW
- The undo history in BBEdit is deep and per-document. Make one change at 
  a time so the user can step back to any point.
- Use Find Differences to show a before/after of a revised passage rather 
  than simply replacing it. The user should choose, not the agent.
- Word count targets matter to writers. Use bbedit_get_word_count and 
  report progress toward a target when asked.

VOICE
- When suggesting edits, preserve the author's voice. Do not replace 
  their sentence rhythm with yours. Offer alternatives, not replacements.
```

---

**Example: Xcode plugin — multiple coaches**

```json
{
  "type": "coach", "name": "app-development",
  "label": "App Development", "default": true,
  "file": "prompts/coach-app.md",
  "description": "SwiftUI, UIKit, app architecture, HIG."
},
{
  "type": "coach", "name": "scripting",
  "label": "Scripting & Automation",
  "file": "prompts/coach-scripting.md",
  "description": "Swift scripts, swift-sh, shell integration, Automator."
},
{
  "type": "coach", "name": "framework",
  "label": "Framework & Package Development",
  "file": "prompts/coach-framework.md",
  "description": "Swift packages, SPM, API design, documentation."
}
```

```json
"context_hints": {
  "app-development": { "extensions": ["swift"], "path_contains": ["Sources/App", "Views", "ViewModels"] },
  "framework":       { "extensions": ["swift"], "path_contains": ["Sources/Lib", "Package.swift"] },
  "scripting":       { "extensions": ["swift", "sh"], "path_contains": ["Scripts"] }
}
```



Plugins declare `entitlements_required` in their manifest. Majordomo checks each declared entitlement against the current TCC grants before enabling the plugin's tools.

On install, if a required entitlement is not yet granted, Majordomo shows a permission row in the Plugins tab with the same Allow / Open Privacy & Security pattern used in the Permissions tab.

A plugin **cannot** use entitlements it did not declare. The script runner checks the declared list before execution and returns a permission error if a script attempts to invoke an undeclared capability.

### 13.6 Plugin Security

**Source visibility.** Before a plugin is activated, the user can inspect every script file from the Plugins tab. The UI shows each file as syntax-highlighted source in a sheet. There is no "install and trust automatically" path.

**No compiled code.** Plugins may only contain JXA scripts, AppleScript source, and shell scripts. Compiled binaries, Swift packages, and dynamic libraries are rejected at install time.

**Shell script restrictions.** `shell` scripts execute in a restricted environment:
- `PATH` is limited to `/usr/bin:/bin:/usr/local/bin`
- No network access (`DISABLE_NETWORK=1` via sandbox profile)
- No write access outside `/tmp` and the plugin's own directory
- `HOME` is set to the plugin's bundle directory

**Parameter injection.** Parameters are passed as a single JSON-encoded argument, never interpolated into script source. Scripts that construct shell commands from parameters must do so safely — the manifest linter warns on common patterns.

### 13.7 Plugin UI — Plugins Tab

The main window gains a fourth tab: **Plugins**.

**Installed plugins list.** Each row shows:
- Plugin name and version
- Target app name (with a dot indicating whether the app is installed)
- Number of tools provided
- Enabled/disabled toggle
- ··· menu → View Source · Uninstall

**Empty state:** *"Plugins add support for third-party apps. Drop a `.majordomo-plugin` bundle here, or browse the community registry."*

**Installation methods:**
1. Drag a `.majordomo-plugin` bundle onto the Plugins tab or the app icon
2. Double-click a `.majordomo-plugin` file in Finder (registered file association)
3. **Install from URL** button — fetches a `.majordomo-plugin` bundle from a HTTPS URL, shows a preview before confirming

**View Source sheet.** Tapping ··· → View Source shows the full directory tree of the plugin with each file readable. The user must dismiss this sheet before the plugin is activated for the first time.

### 13.8 Community Registry

The registry is a GitHub repository: `majordomo-mcp/plugins`. Each plugin is a subdirectory containing the bundle. Pull requests are the submission mechanism.

Majordomo does not query the registry at runtime. The **Browse Registry** button opens `https://github.com/majordomo-mcp/plugins` in the browser. This keeps the app's network surface area at zero — no telemetry, no update checks, no registry API calls.

### 13.9 Tab Badge

The Plugins tab badge lights when:
- A plugin's target app is installed but the plugin is disabled
- A required entitlement for an installed plugin is not granted

### 13.10 File Structure Addition

```
Majordomo/
├── ...
└── Plugins/
    ├── PluginManager.swift        # loads, validates, enables/disables plugins
    ├── PluginManifest.swift       # Codable manifest model
    ├── PluginScriptRunner.swift   # OSAScript + Process execution
    ├── PluginTool.swift           # wraps a plugin script as an MCPTool
    └── PluginInstaller.swift      # drag-drop, file association, URL install
```

---



**Loopback-only binding.** The HTTP server binds exclusively to `127.0.0.1` via `NWParameters.requiredLocalEndpoint`. This is not a configuration default — it is enforced in code. `127.0.0.1` is the loopback interface, which the OS does not route to any network adapter. No device on the local subnet, VPN, or any other network can reach it regardless of firewall state. Majordomo does not advertise via Bonjour or any other network discovery protocol.

**No authentication in v1.** The threat model assumes a single-user Mac where any process on localhost is trusted. Multi-user support (with per-user tokens) is a future consideration.

**AppleScript injection.** All AppleScript strings are constructed from a fixed template with parameterized substitution. User-supplied strings are escaped before interpolation. No raw AppleScript is accepted from MCP clients.

**Plugin script execution.** Plugin scripts run in a restricted environment as defined in Section 13.6. No compiled code is permitted. Shell scripts are network-isolated. Parameters are never interpolated into script source.

**Subprocess execution.** The permitted subprocesses are `/usr/bin/shortcuts` and plugin shell scripts running under the restricted profile above. No other shell execution paths are available.

**Sensitive data in tool responses.** Tools do not cache responses. File contents and message bodies are passed through once and discarded.

**Script execution safety.** Scripts run tool calls with parameters recorded at creation time. Parameters are validated against each tool's input schema before execution. A script cannot call a tool the user has not already granted the underlying permission for.

---

## 14. Settings

Majordomo exposes a Settings window (`Cmd-,`, standard macOS convention) with the following panels.

### 14.1 Server

| Setting | Default | Notes |
|---|---|---|
| Preferred port | `3742` | Tried first on every launch |
| Start at login | On | Registered via `SMAppService` |

**Bind address: loopback only.** Majordomo binds exclusively to `127.0.0.1`. It does not bind to `0.0.0.0`, the LAN interface, or any network-accessible address. This is enforced in `Network.framework` by setting `requiredLocalEndpoint` on `NWParameters` — not a configuration option, not a default:

```swift
let params = NWParameters.tcp
params.requiredLocalEndpoint = NWEndpoint.hostPort(
    host: NWEndpoint.Host("127.0.0.1"),
    port: NWEndpoint.Port(integerLiteral: 0) // 0 = OS assigns available port
)
let listener = try NWListener(using: params)
```

Binding to `127.0.0.1` means the socket is unreachable from any other device on the local network. No firewall rule, VPN config, or network change can expose it — the loopback interface is host-only at the OS level.

**No Bonjour.** Majordomo does not advertise via `NetService` or any mDNS mechanism. Bonjour operates on the LAN interface, which would reveal the existence of the service to every device on the subnet — an information leak with no benefit, since remote clients cannot connect to a loopback address anyway.

**Port discovery via port file.** Instead of network advertisement, Majordomo writes the bound port to a file immediately after the listener starts:

```
~/Library/Application Support/app.majordomo/.port
```

Contents: a single integer, e.g. `3742` or `51204`. The file is deleted when the server stops. Local MCP clients — including the auto-patch mechanism — read this file to discover the current port without any network traffic.

**Auto-patching known clients.** When the port changes (or on first launch), Majordomo reads `.port`, constructs `http://127.0.0.1:<port>/mcp`, and rewrites the URL in each configured client's config file. One-time permission per client, granted in Settings. On conflict or change, the status strip shows:

> *Moved to port 51204. Claude Desktop config updated.*

If auto-patch is off:

> *Port changed to 51204. Update your MCP client config.*  **Copy URL**


### 14.2 Prompts

Both `macos-coworker` and `macos-coach` are displayed as editable Markdown documents using **swift-markdown** for rendering and a plain `TextEditor` for editing. The spec'd content in Sections 8 and 11 is the default for each.

| Control | Behaviour |
|---|---|
| Edit button | Switches from rendered Markdown to raw editor |
| Reset to Default | Restores the bundled spec content, with a confirmation sheet |
| Agent-editable | Yes — the agent can call `prompt_update` to propose changes; changes are shown as a diff before applying |

Prompt files are stored at:
```
~/Library/Application Support/app.majordomo/prompts/macos-coworker.md
~/Library/Application Support/app.majordomo/prompts/macos-coach.md
```

If the file exists it takes precedence over the bundle. If it is deleted, the bundled default is restored on next launch.

### 14.3 User Profile

Skill-level persistence is **opt-in**, disabled by default. When enabled:

- The agent reads and writes a `user_profile` MCP resource stored at `~/Library/Application Support/app.majordomo/user-profile.md` — a plain Markdown file the user can also read and edit directly.
- The profile is agent-written prose: *"Prefers step-by-step explanations. Comfortable with Finder but unfamiliar with Terminal. Has used keyboard shortcuts after prompting."*
- A **View / Edit Profile** button in Settings opens it in the same swift-markdown editor used for prompts.
- A **Clear Profile** button deletes the file with a confirmation sheet.

### 14.4 Logs

| Setting | Default | Notes |
|---|---|---|
| Retain logs for | 30 days | Options: 7 / 30 / 90 days / Forever |
| Strip parameter values after pattern extraction | On | Replaces param values with `[redacted]` in stored log entries once the sequence matcher has processed them |
| Include parameter values in log viewer | Off | When off, viewer shows tool names and timestamps only |

A **Delete All Logs** button clears `callog.json` immediately, with a confirmation sheet.

---

## 15. Connections & Logs

### 15.1 Connections Tab

The window gains a third tab: **Connections**. It contains two sections stacked vertically.

**Connected Clients** lists every MCP client currently holding an active session:

| Column | Content |
|---|---|
| Client name | Inferred from HTTP `User-Agent` or `X-Client-Name` header |
| Connected since | Relative time ("Connected 4 minutes ago") |
| Tool calls this session | Running count |
| Disconnect button | Closes the session; client must reconnect |

An empty state reads: *"No clients connected. Configure your MCP client to connect to `http://localhost:3742/mcp`."*

**Persistent connection for Siri.** The Siri / App Intents bridge maintains a persistent SSE (Server-Sent Events) connection rather than stateless HTTP. When `RunAssistantTaskIntent` fires, Majordomo pushes the task onto the SSE stream of the most recently active client and awaits a response, blocking the intent handler's async context. The SSE connection is identified by `X-Client-Name: majordomo-siri-bridge` and always appears first in the client list with a Siri icon.

### 15.2 Log Viewer and Agent Summary

Below the client list, a scrollable log shows recent tool invocations. Each entry shows:

```
2026-04-02 08:14:33  calendar_list_events    Claude Desktop    ✓  12ms
2026-04-02 08:14:31  reminders_list          Claude Desktop    ✓   8ms
2026-04-02 08:09:17  spotlight_search        Claude Desktop    ✗  —   Permission denied → manual fallback delivered
2026-04-02 07:55:01  script_run [morning]    Siri Bridge       ✓  34ms
2026-04-02 07:42:11  home_set [Shade 2]      Claude Desktop    ✗  —   Device timeout · retried 2× · camera: still open
```

**The log is primarily for agents to read, not humans.** A `log_get` tool returns the log in structured JSON. The agent can summarize it in plain English on request:

> "What happened this morning?"
> → agent calls `log_get(since: "07:00", until: "09:00")`
> → "Between 7 and 9 AM I ran your morning briefing, checked your calendar and reminders, and tried to close Shade 2. The shade didn't respond — I retried twice and the camera confirmed it's still open. Everything else ran cleanly."

This is the audit trail. Not a dashboard the user studies, but a ledger the agent can read and explain.

```swift
name: "log_get"
description: "Return tool call history as structured JSON, filterable by time range, 
              client, tool name, or result status. Use this to answer questions about 
              what Majordomo has done."
```

Input:
```json
{
  "since":   { "type": "string", "format": "iso8601" },
  "until":   { "type": "string", "format": "iso8601" },
  "tool":    { "type": "string", "description": "Filter to a specific tool name" },
  "status":  { "type": "string", "enum": ["success", "failure", "fallback"] }
}
```

**Human-facing controls:**
- **Filter** field — filters by tool name or client name
- **Export** — saves the visible log to a `.csv` file
- **Clear** — clears the log

Parameter values are shown or hidden based on the **Include parameter values in log** setting (Section 14.4). When shown, they appear in an expandable row beneath the entry.

### 15.3 UI Summary — Three Tabs

| Tab | Badge condition |
|---|---|
| Permissions | One or more permissions in "Not Set" state |
| Scripts | One or more agent-suggested scripts not yet saved |
| Connections | One or more tool call errors in the last hour |

---

## 16. Voice Interface

### 16.1 Philosophy

Voice is not a gimmick layer on top of a text interface. It is a first-class input mode for users who are away from the keyboard, users with accessibility needs, and users who find speaking more natural than typing. When voice is active, Majordomo listens, understands, acts, and responds — without the user touching anything.

### 16.2 Architecture

```
Microphone
    │
    ▼
SFSpeechRecognizer          ← on-device, no cloud
(continuous transcription)
    │
    ▼
Wake word / push-to-talk filter
    │
    ▼
Connected AI client         ← via SSE, same path as Siri bridge
(interprets + calls tools)
    │
    ▼
AVSpeechSynthesizer         ← system voices, macOS 26
(spoken response)
```

All speech recognition runs on-device via `SFSpeechRecognizer`. No audio leaves the Mac.

### 16.3 Activation Modes

| Mode | Mechanism | Default |
|---|---|---|
| Push-to-talk | Global hotkey via `NSEvent.addGlobalMonitorForEvents` (default: double-Fn) | ✅ On |
| Menu bar click | Click the Majordomo menu bar icon → voice popover | ✅ On |
| Siri via App Intents | "Hey Siri, [task] with Majordomo" | ✅ (Siri-dependent) |
| Wake word | Off — see note below | Off |
| Disabled | Voice input off entirely | — |

**Custom wake words are not implemented.** Apple's Human Interface Guidelines reserve system-level wake word activation for Siri. Majordomo does not compete with that model. Voice activation uses the system-provided push-to-talk hotkey or the Siri/App Intents bridge. Users who want hands-free activation use "Hey Siri" with the `RunAssistantTaskIntent` pathway.

**Global hotkey safety.** The push-to-talk hotkey uses `NSEvent.addGlobalMonitorForEvents` — not `CGEventTap`. This is an intentional security decision: `addGlobalMonitorForEvents` cannot intercept keystrokes in secure input fields (password prompts, 1Password, secure terminal input). `CGEventTap` can. Majordomo chooses the safer API.

**System-wide activation.** Push-to-talk and menu bar voice work from any app without switching focus. The global hotkey is registered at the system level and triggers the voice overlay regardless of the frontmost application.

### 16.4 Voice Overlay

When voice is activated from outside the Majordomo window, a minimal floating overlay appears in the top-right corner of the screen — not a window, not a sheet, just a waveform and a brief transcript line:

```
  ╭──────────────────────────────╮
  │  🎙 ▁▂▃▄▃▂▁  Listening…      │
  ╰──────────────────────────────╯
```

When the agent responds with audio, the overlay shows the spoken text in real time. It dismisses automatically when the response completes. The user's focus never moved.

### 16.5 Response Voice

Majordomo reads agent responses aloud using `AVSpeechSynthesizer` with the user's selected system voice. Settings:

| Setting | Default |
|---|---|
| Read responses aloud | On |
| Voice | System default |
| Speaking rate | Normal |
| Stop speaking on input | On |

### 16.6 Ambient Mode

A toggle in Settings enables **Ambient Mode** — a persistent listening state where Majordomo acts as the primary interface rather than a background service. In Ambient Mode:

- The window is replaced by a minimal HUD (waveform + last transcript line)
- Push-to-talk is always active
- Responses are always spoken
- The Dock icon changes to indicate the mode is active

In Ambient Mode the Mac's speaker and microphone are the interface.

---

## 17. Research & Knowledge

### 17.1 Purpose

Majordomo gives the agent access to current, trusted information sources so it can answer questions, not just execute commands.

### 17.2 Research Tools

| Tool | Source | Notes |
|---|---|---|
| `web_search` | Configurable provider (default: DuckDuckGo) | No API key required for DDG |
| `web_fetch` | `URLSession` | Fetches and strips HTML to readable text |
| `wikipedia_search` | Wikipedia API | No key required |
| `wikipedia_get` | Wikipedia API | Full article, plain text |
| `wolfram_query` | Wolfram Alpha API | Computational queries; requires API key |
| `trusted_source_search` | User-curated list | Scopes search to approved domains |

### 17.3 Privacy Model for Research

Research tools make network requests — the only Majordomo tools that do. The permission model reflects this:

- Each research tool is independently toggle-able in the Permissions tab under a new **"Research"** section
- `web_search` and `web_fetch` show a new permission row: **"Search the web and fetch pages"**
- Wolfram Alpha shows a separate row that also prompts for the API key
- The consequence string: *"Majordomo will send your search queries to the selected provider. Queries are not associated with your Apple ID."*

### 17.4 Trusted Sources

Users can curate a list of trusted domains in Settings → Research. When `trusted_source_search` is called, results are filtered to these domains. Example defaults:

```
wikipedia.org
wolframalpha.com
developer.apple.com
stackoverflow.com
```

The agent uses `trusted_source_search` by preference for factual queries. It falls back to `web_search` when no trusted source has coverage.

### 17.5 Search Provider

DuckDuckGo is the default because it requires no API key and has a strong privacy policy. Users can configure alternative providers in Settings:

| Provider | API key required |
|---|---|
| DuckDuckGo | No |
| Brave Search | Yes |
| Bing | Yes |
| User-defined | Yes (custom endpoint) |

---

## 17.6 RSS & News

RSS is a first-class built-in, not an API plugin. It requires no authentication, no configuration, and is the foundation of the news page feature. Every source in Apple News has an RSS feed — Majordomo reads those feeds directly.

**`rss_fetch`**

Fetches and parses one or more RSS or Atom feeds, returning structured articles.

```swift
name: "rss_fetch"
description: "Fetch and parse RSS/Atom feeds. Returns structured articles 
              sorted by publication date. Use this to get news for briefings 
              or to include in a news page."
annotations:
  readOnlyHint: true
  openWorldHint: true
```

Input schema:

```json
{
  "feeds": {
    "type": "array",
    "items": { "type": "string" },
    "description": "Array of RSS/Atom feed URLs."
  },
  "limit": {
    "type": "integer",
    "default": 10,
    "description": "Maximum articles per feed."
  },
  "since_hours": {
    "type": "integer",
    "default": 24,
    "description": "Only return articles published within this many hours."
  }
}
```

Returns an array of articles: `{ title, source, url, excerpt, published_at, feed_url }`.

---

**`news_page_open`**

Generates a formatted HTML news page from user-configured sources and opens it in the default browser. The HTML is written to a temp file in `~/Library/Caches/app.majordomo/news/` and opened with `NSWorkspace.shared.open()`.

```swift
name: "news_page_open"
description: "Generate and open a formatted news page from the user's 
              configured news sources. Opens in the default browser. 
              Use when the user asks to 'show me the news' or 'open my 
              news page'."
annotations:
  readOnlyHint: false
  openWorldHint: true
```

Input schema:

```json
{
  "category": {
    "type": "string",
    "enum": ["Top Stories", "World", "Technology", "Business", "Science"],
    "default": "Top Stories",
    "description": "Category filter to open to."
  }
}
```

The tool calls `rss_fetch` internally for all configured sources, then generates the HTML. No external service is involved — the page is generated entirely on-device from the raw feed data.

### News Page Design

The generated HTML page follows an editorial layout:

- **Masthead**: "Majordomo News" with the current date
- **Category tabs**: Top Stories / World / Technology / Business / Science — filtered from article category metadata or feed tags
- **Hero card**: Full-width feature for the lead story, dark gradient background
- **Story grid**: Three-column card layout — image gradient, source badge, headline, excerpt, timestamp
- **Source pills**: At the top, showing configured sources with per-source brand colors
- **Apple News badge**: Sources known to be in Apple News+ show a small `N` badge. Clicking their articles opens in Apple News rather than the browser when iCloud+ is active.
- **Footer**: Generation timestamp, source count, Refresh button (re-runs `news_page_open`)

The page uses only system fonts and inline CSS. No external resources are fetched at render time — all assets are self-contained. The page respects `prefers-color-scheme` for dark mode.

### Apple News Integration

When the user has an active iCloud account, Majordomo can open article links in Apple News rather than the browser. This serves two cases:

### Apple News Routing

Majordomo routes article links through Apple News when the app is installed and the user has enabled the preference.

**iCloud+ vs Apple News+.** These are separate subscriptions. iCloud+ includes Private Relay and Hide My Email. Apple News+ is the paid news subscription, available standalone or as part of Apple One. The paywall-unlocking benefit is Apple News+. The better reading experience (no ads, no cookie banners, clean layout) is Apple News even without a paid subscription. Majordomo supports both tiers and detects them independently.

| State | Behaviour |
|---|---|
| Apple News not installed | All links open in default browser |
| Apple News installed, free | Links open in Apple News — better reading experience |
| Apple News+ subscription | Same, plus paywalled articles from participating publishers are unlocked |

**Detection:**

```swift
// Is Apple News installed?
let newsInstalled = NSWorkspace.shared
    .urlForApplication(withBundleIdentifier: "com.apple.news") != nil

// Is Apple News+ active? Use StoreKit — no iCloud check needed.
// Falls back gracefully if inconclusive; user preference prevails.
```

**Opening an article:**

```swift
func openArticle(_ url: URL, preferNews: Bool) {
    guard preferNews,
          let newsApp = NSWorkspace.shared
              .urlForApplication(withBundleIdentifier: "com.apple.news")
    else {
        NSWorkspace.shared.open(url)
        return
    }
    // Pass the original article URL directly to Apple News.
    // Apple News performs its own catalog lookup — no article ID needed.
    // If it can't match the article, it shows its own fallback state.
    let config = NSWorkspace.OpenConfiguration()
    NSWorkspace.shared.open([url], withApplicationAt: newsApp,
                            configuration: config, completionHandler: nil)
}
```

**The `majordomo://` URL scheme.** The generated HTML news page is a static file in the browser. Browser-side links can't call Swift code directly, so Majordomo registers a custom URL scheme. Article links in the HTML use:

```
majordomo://open-article?url=https%3A%2F%2Freuters.com%2F...
```

When clicked, macOS routes this to Majordomo.app which calls `openArticle(_:preferNews:)` with the user's preference applied. The scheme is registered in `Info.plist` via `CFBundleURLTypes`.

Registered schemes:

| Scheme | Purpose |
|---|---|
| `majordomo://open-article?url=` | Opens article with News routing |
| `majordomo://news-page-open` | Regenerates and opens the news page |
| `majordomo://brief-open` | Opens Majordomo window to Brief panel |

**Per-source open preference.** Each source row in Settings → News Sources includes an **Open in** selector: `Auto` / `Apple News` / `Browser`. Auto uses Apple News for any source where it's available; the others override. This lets users force browser for sources they prefer reading on the web.

**News Source Configuration:**

```
NEWS SOURCES

□ AP News        feeds.apnews.com/rss/apf-topnews    Auto  ▾  [Remove]
□ BBC World      feeds.bbci.co.uk/news/world/rss.xml  Auto  ▾  [Remove]
□ Reuters        feeds.reuters.com/reuters/topNews     Auto  ▾  [Remove]
□ The Atlantic   theatlantic.com/feed/all              Auto  ▾  [Remove]  ← N+
□ Wall St Journal wsj.com/xml/rss/3_7085.xml           Auto  ▾  [Remove]  ← N+
□ Hacker News    news.ycombinator.com/rss             Browser▾  [Remove]

[+ Add Feed URL]

Refresh frequency:            Every 2 hours  ▾
Include in Morning Brief:     [On]
Open in Apple News:           [On]    ← shown only if Apple News is installed
  Apple News+ detected:  ✓ Subscriber
```

Sources in Apple News+ are marked `N+` in the source row. The toggle only appears when Apple News is installed. The News+ status line appears when the subscription is confirmed via StoreKit.

The same source list feeds both `news_page_open` and the Morning Brief routine — one list, two surfaces.

---

## 18. Smart Home — Direct Matter

### 18.1 Approach

Majordomo speaks Matter directly. It does not use `HomeKit.framework` and does not require the `com.apple.developer.homekit` entitlement. Matter is an open protocol — any application can implement it. Majordomo bundles the `connectedhomeip` SDK (the CSA's open-source implementation) as a Swift Package Manager dependency compiled into the app binary. No approval gates. No dependency on Apple's Home ecosystem.

This means:
- Any Matter-certified device works — whether or not it's in Apple Home
- Automations run in Majordomo's own scheduler, not HomeKit's
- Sunset-relative triggers use WeatherKit's actual sunset time, not HomeKit's calculation
- Non-Matter devices are handled by the lan/ble/usb endpoint plugin types (Section 19)

### 18.2 Commission Flow

Majordomo commissions Matter devices using the bundled SDK's standard pairing flow. The user scans the QR code or enters the numeric code printed on the device. Fabric credentials are stored in Keychain. No HomeKit account, no Apple Home required.

```swift
// Commission via bundled connectedhomeip SDK
let commissioner = MatterDeviceCommissioner()
try await commissioner.commission(
    setupPayload: payload,       // from QR code scan
    fabricCredentials: keychain  // stored locally
)
```

First-time pairing shows: *"Scan the QR code on your device."* The camera opens, user scans, done.

### 18.3 Smart Home Tools

**Discovery & State**

| Tool | Action | readOnly |
|---|---|---|
| `home_list_devices` | All commissioned Matter devices with current state | ✅ |
| `home_get_device` | Full state for one device by name | ✅ |
| `home_get_state` | Full home snapshot — all devices, all characteristics | ✅ |
| `home_list_rooms` | User-defined rooms with their devices | ✅ |
| `home_assign_room` | Assign a device to a room | ❌ |

**Control**

| Tool | Action | readOnly | destructive |
|---|---|---|---|
| `home_set` | Set any capability on any device by name | ❌ | context-dependent |
| `home_run_scene` | Activate a named Majordomo scene | ❌ | ❌ |

**Scenes**

| Tool | Action |
|---|---|
| `home_list_scenes` | All saved scenes |
| `home_create_scene` | Create a scene from current device states or explicit values |
| `home_delete_scene` | Remove a scene |

**Automations**

| Tool | Action |
|---|---|
| `home_list_automations` | All saved automations |
| `home_create_automation` | Create an automation with trigger and actions |
| `home_delete_automation` | Remove an automation |
| `home_enable_automation` | Enable or disable an automation |

### 18.4 Automation Triggers

Automations run in Majordomo's own scheduler process, launched at login via `SMAppService`. No Home Hub required. No HomePod. The Mac running Majordomo is the hub.

**Disclosure.** Every automation with a time-based or solar trigger displays a persistent notice in both the creation confirmation and the automation row:

> *"This automation runs on this Mac. If your Mac is asleep or Majordomo isn't running, it won't fire."*

This is not a warning — it's a factual description of how the system works. The agent states it plainly when creating the automation and the UI shows it on every time-based automation row.

**Missed automation detection.** On wake from sleep, Majordomo checks whether any scheduled automations were missed while the Mac was asleep. If a missed automation is found, it appears in the Brief panel:

> *"Kitchen West Windows automation was scheduled for 6:12 PM while your Mac was asleep. The windows may still be open."*

The agent does not retroactively fire missed automations — physical state may have changed. It reports and lets the user decide.

**`time`** — Fixed time of day:
```json
{ "type": "time", "time": "22:30", "days": ["mon","tue","wed","thu","fri","sat","sun"] }
```

**`solar`** — Sunrise or sunset with offset. Majordomo computes the actual solar time daily using WeatherKit sun events for the device's location:

```json
{ "type": "solar", "event": "sunset", "offset_minutes": -90 }
```

```swift
// Compute actual sunset for today
let weather = try await WeatherService.shared.weather(for: location, including: .daily)
let sunset = weather.dailyForecast.first?.sun.sunset
let triggerTime = sunset?.addingTimeInterval(-90 * 60)
```

This is more accurate than HomeKit's astronomical calculation and runs entirely without an Apple Home account.

**`device_state`** — When a device characteristic changes:
```json
{ "type": "device_state", "device": "Front Door", "characteristic": "ContactState", "value": 1 }
```

**`presence`** — Majordomo monitors whether the Mac is in use and can trigger on wake/sleep as a presence proxy:
```json
{ "type": "presence", "event": "sleep" }
```

### 18.5 Accessory Disambiguation

Matter devices have names and can be grouped into user-defined rooms. When the agent needs information that isn't in the device metadata, it asks once and writes the answer to the user profile.

```
User: "Close the west-facing kitchen windows 90 minutes before sunset."
Agent: "Which of these are west-facing — Left, Right, or both?"
User:  "Both."
Agent: [creates automation, writes to user profile]
```

On any future request the agent already knows. If the user volunteers the information upfront, the question is skipped.

### 18.6 Safety Constraints

```
SMART HOME
- Never unlock a door without confirming the specific lock by name.
- When setting temperature, confirm if more than 3°C from current.
- Scenes are safe to activate if the user names them directly.

CREATING AUTOMATIONS
- Before creating, state in plain English: what it does, when it triggers,
  which devices it affects. Wait for confirmation.
- For solar triggers, explain the seasonal range:
  "90 minutes before sunset — around 3:30 PM in December, 6:50 PM in June."
- After creating, confirm: "This runs on this Mac. Majordomo needs to be
  running for time-based automations to fire."
- Never delete an automation without showing what it does and confirming.
```

### 18.7 Home State as Context

`home_get_state` returns a snapshot the agent can hold in context for ambient awareness:

```json
{
  "rooms": [
    {
      "name": "Living Room",
      "devices": [
        { "name": "Floor Lamp",  "type": "light",      "on": true,  "brightness": 60 },
        { "name": "Thermostat",  "type": "thermostat", "current": 68, "target": 70 }
      ]
    }
  ]
}
```

An agent with this context can answer "is the heating on?" without a tool call.

### 18.8 Non-Matter Devices

Smart home devices that aren't Matter-certified are handled by the Endpoint Plugin system (Section 19): Philips Hue via `lan-http`, Govee via `ble`, legacy devices via `lan-tcp`. The smart home tool namespace (`home_*`) is reserved for Matter. Non-Matter device tools use their plugin's declared `tool_prefix`.

---

## 19. Endpoint Plugins

### 19.1 The Unifying Abstraction

A phone number, a web API, an RSS feed, an email address, a local network device — these are all the same thing: **an address that routes to a service that accepts inputs and produces outputs**. The protocol is just the interaction layer.

Majordomo's Endpoint Plugin type unifies all of these under one manifest format. Every addressable service becomes a set of tools the agent can call, with agentic instructions for how to use them.

| Endpoint type | Address format | Protocol handler | Direction |
|---|---|---|---|
| Web API | `https://api.example.com` | HTTP request/response | Bidirectional |
| Web page | `https://example.com` | Fetch + parse | Read |
| RSS/Atom feed | `https://example.com/feed` | Feed parser | Read |
| Phone number | `tel:+14155551234` | Continuity Calls + DTMF | Bidirectional |
| Email address | `mailto:support@example.com` | Mail.app / SMTP | Send |
| SMS number | `sms:+14155551234` | Messages.app | Bidirectional |
| App URL scheme | `appname://action` | NSWorkspace URL dispatch | Send |
| WebSocket (cloud) | `wss://example.com/ws` | URLSessionWebSocketTask | Bidirectional |
| **Local network device** | `lan://ssdp:<service-type>` or `lan://<ip>:<port>` | SSDP discovery + local HTTP/WS | Bidirectional |

The `lan` endpoint type is the full class of devices on the local network that aren't HomeKit-compatible: smart TVs, NAS drives, 3D printers, self-hosted services, network appliances. They are discovered via SSDP/UPnP or addressed directly by IP. They never leave the local network — no cloud dependency.

### 19.2 Bundle Format

```
ChaseSupport.majordomo-plugin/
├── manifest.json
├── auth.json              ← optional — API keys, tokens (stored in Keychain)
└── prompts/
    ├── coworker.md        ← behavioral constraints
    └── coach.md           ← domain expertise (optional, multiple named coaches)
```

### 19.3 Manifest Schema

The `endpoint` block replaces the `base_url` field from the old API plugin format. All other plugin fields (name, id, version, tools, prompts) remain identical.

```json
{
  "name": "Chase Credit Card Support",
  "id": "com.chase.support.majordomo-plugin",
  "type": "endpoint",
  "version": "1.0.0",
  "description": "Call Chase credit card support, navigate the IVR, and get to a human.",

  "endpoint": {
    "type": "phone",
    "address": "tel:+18004322000",
    "label": "Chase Credit Card Support"
  },

  "tools": [
    {
      "name": "chase_call_support",
      "description": "Call Chase credit card support and navigate to a human agent.",
      "handler": "phone",
      "annotations": { "readOnlyHint": false, "openWorldHint": true }
    }
  ],

  "prompts": [
    {
      "type": "coworker",
      "file": "prompts/coworker.md",
      "description": "How to handle the Chase IVR and human agent interaction."
    }
  ]
}
```

A web API endpoint:

```json
"endpoint": {
  "type": "https",
  "base_url": "https://api.github.com",
  "auth": { "type": "bearer", "keychain_key": "github_token" }
}
```

An RSS feed endpoint:

```json
"endpoint": {
  "type": "rss",
  "address": "https://feeds.apnews.com/rss/apf-topnews",
  "label": "AP News Top Stories"
}
```

### 19.4 Protocol Handlers — Complete Taxonomy

Every connection layer macOS supports maps to a built-in handler. Plugin authors declare their endpoint type; Majordomo routes tool calls to the correct framework. No driver code required.

**Network**

| Type | Handler | Notes |
|---|---|---|
| `https` | `URLSession` | REST APIs, cloud services |
| `rss` | Feed parser | Structured articles |
| `websocket` | `URLSessionWebSocketTask` | Cloud WebSocket |
| `lan-http` | `URLSession` to local IP | HTTP REST on LAN |
| `lan-ws` | `URLSessionWebSocketTask` to local IP | WebSocket on LAN |
| `lan-tcp` | `NWConnection` TCP | Telnet-style A/V receivers, DMX |
| `lan-udp` | `NWConnection` UDP | Roku ECP, LIFX, raw datagrams |

**Communication**

| Type | Handler | Notes |
|---|---|---|
| `phone` | CallKit + DTMF + SFSpeechRecognizer | Continuity + iPhone |
| `mailto` | Mail.app | Send only |
| `sms` | Messages.app via AppleScript | Send; receive via polling |
| `appurl` | `NSWorkspace.open(_:)` | URL scheme dispatch |

**Matter**

| Type | Handler | Notes |
|---|---|---|
| `matter` | MatterSupport framework | Dynamic cluster reading; Section 19.4c |

**Bluetooth**

| Type | Handler | Notes |
|---|---|---|
| `ble` | CoreBluetooth `CBCentralManager` | BLE GATT profiles |
| `bluetooth-classic` | IOBluetooth | Legacy Bluetooth devices |

**USB**

| Type | Handler | Notes |
|---|---|---|
| `usb-hid` | IOHIDDevice | Drawing tablets, gamepads, custom HID |
| `usb-serial` | IOSerialBSDClient | Arduino, lab equipment, sensors |
| `usb-midi` | CoreMIDI | Synthesizers, controllers, lighting desks |

### 19.4a LAN Endpoint Specification

**Discovery methods:**

| Method | Mechanism | Use when |
|---|---|---|
| `ssdp` | UPnP/SSDP multicast | Samsung, Sonos, UPnP devices |
| `mdns` | Bonjour/mDNS | Hue Bridge, printers, modern devices |
| `fixed` | Static IP or hostname | Fixed LAN addresses |
| `scan` | Subnet scan on known port | Legacy devices with no discovery |

**Pairing methods:**

| Method | Flow |
|---|---|
| `none` | No pairing required |
| `on-screen` | User accepts on device display |
| `pin` | User enters PIN shown on device |
| `token` | Device issues token; Keychain stored |
| `api-key` | Pre-shared key entered in plugin settings |

**State methods:**

| Method | Mechanism |
|---|---|
| `poll` | Majordomo polls on interval |
| `websocket-push` | Device pushes state on open connection |
| `webhook` | Device POSTs to Majordomo on change |
| `none` | Stateless — query per tool call |

### 19.4b Device Capabilities Vocabulary

Any plugin declaring `capabilities` gets auto-generated standard tools prefixed with `tool_prefix`. Plugin authors only write tools outside this vocabulary.

```json
"capabilities": {
  "power":       { "type": "boolean" },
  "volume":      { "type": "integer",  "min": 0, "max": 100 },
  "mute":        { "type": "boolean" },
  "brightness":  { "type": "integer",  "min": 0, "max": 100 },
  "color":       { "type": "object",   "properties": { "hue": {}, "saturation": {}, "kelvin": {} } },
  "input":       { "type": "string",   "enum": ["hdmi1", "hdmi2", "tv", "art"] },
  "playing":     { "type": "boolean" },
  "track":       { "type": "string",   "readonly": true },
  "art_mode":    { "type": "boolean" },
  "temperature": { "type": "number",   "unit": "celsius" },
  "humidity":    { "type": "number",   "unit": "percent",  "readonly": true },
  "lock":        { "type": "boolean" },
  "battery":     { "type": "integer",  "min": 0, "max": 100, "readonly": true },
  "motion":      { "type": "boolean",  "readonly": true }
}
```

### 19.4c Matter: Dynamic Cluster Reading and Custom Device Types

Matter devices are self-describing. Majordomo reads the descriptor cluster at connection time and maps clusters to the capability vocabulary — no plugin required for standard device types.

```
Connect to Matter device
    │
    ▼
Read descriptor cluster → device type + supported clusters
    │
    ▼
Map clusters → capabilities
    ├── OnOff          → power
    ├── LevelControl   → brightness
    ├── ColorControl   → color
    ├── Thermostat     → temperature, humidity, mode
    ├── DoorLock       → lock
    └── RvcRunMode     → run_mode
    │
    ▼
Auto-generate prefixed tools
```

**Standard Matter device types auto-mapped:**

| Matter device type | Auto-generated capabilities |
|---|---|
| Dimmable Light | power, brightness |
| Extended Color Light | power, brightness, color |
| Thermostat | temperature, humidity |
| Door Lock | lock |
| Window Covering | position |
| Occupancy Sensor | motion (readonly) |
| Air Quality Sensor | air_quality, pm2_5, voc (readonly) |
| Robot Vacuum / Mop | cleaning_state, run_mode, clean_mode, battery |

**Robot vacuum cluster mapping:**

| Matter cluster | Capability | Values |
|---|---|---|
| `RvcOperationalState` | `cleaning_state` | stopped / running / paused / seeking-charger / charging / docked / error |
| `RvcRunMode` | `run_mode` | idle / cleaning / mapping |
| `RvcCleanMode` | `clean_mode` | vacuum / mop / vacuum-and-mop |
| `ServiceArea` | `service_areas` | Room list with IDs and names |
| `BatteryPowerSource` | `battery` | 0–100% (readonly) |

**macOS Home.app gap.** Home.app on macOS doesn't yet expose robot vacuum controls — this is an Apple UI limitation, not a MatterSupport framework limitation. Majordomo uses MatterSupport directly and is not constrained by Home.app's rendered UI.

---

#### Dynamic Support for New Matter Device Types

MatterSupport is a high-level framework — Apple implements the device types they choose to support on their release cycle. Majordomo does not wait for that cycle. Everything runs in Swift, compiled into the Majordomo app binary. No additional software installs are required from the user.

**Matter's wire protocol is a generic attribute model.** Every device speaks the same underlying language: read attribute, write attribute, invoke command. Cluster IDs and attribute IDs are numbers defined in the CSA specification. Majordomo accesses unsupported device types via two paths, in preference order:

**1. MatterSupport generic attribute layer (preferred)**

MatterSupport may expose `readAttribute(cluster:, attribute:)` and `invokeCommand(cluster:, command:)` APIs alongside its high-level device abstractions. If available, Majordomo uses these for commissioning, credential management, and direct attribute access — all within Apple's framework, no additional code.

```swift
// Preferred path — MatterSupport generic access
let value = try await matterSession.readAttribute(
    cluster: ClusterID(0x0099),
    attribute: AttributeID(0x0000)
)
```

**2. Bundled Matter SDK via SPM (fallback)**

When MatterSupport doesn't expose generic attribute access for a device type, Majordomo falls back to the CSA's open-source Matter SDK, included as a Swift Package Manager dependency compiled into the Majordomo app binary. Users see a single `.app` download — the Matter SDK is statically linked, invisible, requires no separate installation.

```swift
// Package.swift
.package(url: "https://github.com/project-chip/connectedhomeip", ...)
```

Fabric credentials are provisioned by MatterSupport during commissioning. The bundled SDK uses those credentials for post-commission attribute communication. Commissioning always goes through Apple's native flow; the fallback only affects the attribute interaction layer.

The two paths are transparent to plugin authors. A plugin manifest declares cluster specs; Majordomo's Matter handler routes attribute calls through whichever path is available at runtime.

#### Plugin-Defined Cluster Specs

A Matter endpoint plugin can declare raw cluster specs directly from the CSA specification. Majordomo generates tools from those specs at runtime, independent of whether MatterSupport knows the device type. This means any new Matter device type can be supported the day its spec is published — no Majordomo release, no Apple OS update.

```json
{
  "name": "Matter EV Charger",
  "id": "com.example.ev-charger.majordomo-plugin",
  "type": "endpoint",
  "tool_prefix": "ev_charger",

  "endpoint": {
    "type": "matter",
    "device_type_id": "0x050C",
    "discovery": { "method": "matter-commission" },
    "cluster_mapping": "plugin-defined"
  },

  "matter_clusters": [
    {
      "cluster_id": "0x0099",
      "name": "EnergyEvse",
      "attributes": [
        { "id": "0x0000", "name": "State",          "type": "enum8",   "access": "read" },
        { "id": "0x0001", "name": "SupplyState",     "type": "enum8",   "access": "read" },
        { "id": "0x0021", "name": "SessionEnergy",   "type": "int64u",  "access": "read",
          "unit": "milliwatt-hours" }
      ],
      "commands": [
        {
          "id": "0x0001",
          "name": "EnableCharging",
          "fields": [
            { "id": 0, "name": "ChargingEnabledUntil", "type": "epoch-s", "optional": true },
            { "id": 1, "name": "MinimumChargeCurrent",  "type": "int64s" },
            { "id": 2, "name": "MaximumChargeCurrent",  "type": "int64s" }
          ]
        },
        { "id": "0x0002", "name": "DisableCharging" }
      ]
    }
  ],

  "tools": [
    {
      "name": "ev_charger_get_state",
      "description": "Returns charger state, supply state, and session energy used.",
      "reads": ["EnergyEvse.State", "EnergyEvse.SupplyState", "EnergyEvse.SessionEnergy"]
    },
    {
      "name": "ev_charger_enable",
      "description": "Start charging. Optionally set a stop time and current limits.",
      "invokes": "EnergyEvse.EnableCharging"
    },
    {
      "name": "ev_charger_disable",
      "description": "Stop charging immediately.",
      "invokes": "EnergyEvse.DisableCharging"
    }
  ]
}
```

The `matter_clusters` block is a machine-readable excerpt of the published CSA spec. Cluster IDs, attribute IDs, and command parameters are copied from the specification document. Majordomo's Matter handler performs raw attribute reads and command invocations at runtime using whichever Swift path is available — MatterSupport generic layer, or the bundled SPM-compiled Matter SDK.

#### Community Matter Spec Repository

Majordomo maintains a local spec directory alongside the plugin directory:

```
~/Library/Application Support/app.majordomo/matter-specs/
    device-type-0x050C.json    ← EV charger
    device-type-0x0101.json    ← washing machine
    device-type-0x0305.json    ← microwave oven
    device-type-0x0071.json    ← water heater
```

These files follow the `matter_clusters` schema. When the CSA ratifies a new device type, the community publishes a spec file. Users drop it in this directory and Majordomo generates tools for any commissioned device of that type — no app update, no OS release.

The community registry's `matter-specs/` subdirectory is the distribution channel. A spec file is a single JSON drop; no code, no compilation. The commissioning QR code flow through MatterSupport is unchanged regardless of which spec path is used.

**Commission flow.** All devices use Apple's native `MatterAddDeviceRequest` — the same QR/numeric code flow as Home.app. Commissioning always goes through MatterSupport; the spec path only affects post-commission attribute communication.



### 19.4d Bluetooth Endpoints

**BLE.** Plugins declare GATT service UUIDs. Common profiles map to capabilities automatically.

```json
"endpoint": {
  "type": "ble",
  "services": ["0x180F", "0x1809"],
  "discovery": { "method": "ble-scan", "name_prefix": "Govee" }
}
```

Common GATT → capability mappings:
- `0x180F` Battery Service → `battery`
- `0x1809` Health Thermometer → `temperature`
- `0x180D` Heart Rate → `heart_rate`
- `0xFE95` Xiaomi/Govee → via plugin-specific parser

**Bluetooth Classic.** Declares SDP service record UUID.

### 19.4e USB Endpoints

**USB HID.** Plugins declare vendor ID, product ID, and usage page. Majordomo reads HID reports via `IOHIDDevice`.

```json
"endpoint": {
  "type": "usb-hid",
  "vendor_id": "0x046D",
  "product_id_range": ["0xC52B", "0xC548"],
  "usage_page": 1,
  "usage": 6
}
```

**USB Serial.** For Arduino, lab equipment, industrial sensors. Plugins declare baud rate and line protocol; tool scripts read/write the serial port.

```json
"endpoint": {
  "type": "usb-serial",
  "vendor_id": "0x2341",
  "baud_rate": 9600,
  "line_ending": "\n"
}
```

**USB MIDI.** CoreMIDI handles enumeration. Plugins declare device name pattern and message types.

### 19.4f Cloud-Dependent Device Endpoints

Some consumer devices have no local API — all communication routes through the manufacturer's cloud. These are `https` plugins with OAuth2. The plugin author documents the API from official or reverse-engineered sources.

```json
{
  "name": "Aura Frames",
  "id": "com.auraframes.majordomo-plugin",
  "type": "endpoint",
  "tool_prefix": "aura",
  "endpoint": {
    "type": "https",
    "base_url": "https://api.auraframes.com/v3",
    "auth": { "type": "oauth2", "keychain_key": "aura_token" }
  },
  "image_requirements": {
    "format": "jpeg", "max_dimension": 4096, "max_file_size_mb": 10
  },
  "capabilities": {
    "playing":    { "type": "boolean" },
    "brightness": { "type": "integer", "min": 0, "max": 100 }
  },
  "tools": [
    { "name": "aura_list_frames",  "description": "List all connected Aura frames." },
    { "name": "aura_list_albums",  "description": "List photo albums on a frame." },
    { "name": "aura_upload_photo", "description": "Upload a photo to a frame." },
    { "name": "aura_set_album",    "description": "Set the active album on a frame." }
  ]
}
```

The community registry marks cloud-dependent plugins with a `cloud-dependent` badge. These plugins break if the manufacturer changes their API.

### 19.4g The Complete Taxonomy

If macOS can reach it, Majordomo can wrap it:

| Device | Plugin type | Notes |
|---|---|---|
| SwitchBot | `ble` or `https` | BLE local or cloud API |
| Samsung Frame TV | `lan-ws` | SSDP discovery, on-screen pairing |
| LG / Sony TV | `lan-ws` | WebOS / Bravia API |
| Sonos | `lan-http` | SSDP, no pairing |
| Roku / Fire TV | `lan-http` / `lan-udp` | ECP protocol |
| Philips Hue | `lan-http` | mDNS, button pairing |
| Denon / Marantz | `lan-tcp` | Telnet command protocol |
| Any Matter device | `matter` | Dynamic cluster reading, no plugin needed |
| Govee / LIFX | `ble` / `lan-udp` | BLE or UDP |
| Arduino | `usb-serial` | USB enumeration |
| MIDI controller | `usb-midi` | CoreMIDI |
| Wacom tablet | `usb-hid` | IOHIDDevice |
| Aura frame | `https` | Cloud API, OAuth2 |
| Ring / Nest | `https` | Cloud API, OAuth2 |
| BBEdit / Xcode | `app` (AppleScript/JXA) | macOS app, bundle ID |
| Chase support | `phone` | Continuity call |



### 19.5 Phone Endpoint: "On Behalf Of" Ethics

When a phone endpoint plugin initiates a call and reaches a human agent, the agent follows a defined ethical framework based on how human personal assistants operate:

**Disclose immediately.** The agent introduces itself as acting for the user, not as the user:

> *"Hello, I'm an AI assistant calling on behalf of [User's Name] regarding their credit card account ending in 4821. [User Name] has authorized me to [handle this inquiry / navigate to the right department]. They're available to come on the line if needed."*

**Scope is pre-authorized.** The user has explicitly authorized this call by invoking the tool. The agent handles navigational and administrative steps — the user handles identity and decisions.

**Identity always routes to the user.** Security questions, PINs, passwords, and any personal identifier the agent doesn't possess go to the user: *"I'll bring [Name] on the line for that."*

**Notes and handoff.** The agent documents everything — agent name, reference numbers, commitments, timelines — and delivers a summary via `brief_deliver`.

This maps exactly to the established protocol call centers already use for authorized representatives, caregivers, and financial advisors. No new social contract is required.

The coworker prompt for phone endpoint plugins:

```
CALLING ON BEHALF OF THE USER
- Introduce yourself as an AI assistant calling on behalf of [user_name].
  Never introduce yourself as [user_name] or imply you are the user.
- Your opening: "Hello, I'm an AI assistant calling on behalf of 
  [user_name] regarding [purpose]. They've authorized me to handle 
  this and are available to come on the line if needed."
- During IVR: navigate automatically — no disclosure needed for 
  automated systems.
- During human agent phase: handle administrative and navigational 
  steps. Route identity verification and decisions to the user.
- Always save: agent name, reference number, any commitments made,
  expected timelines.
- After the call: deliver a summary via brief_deliver.
```

### 19.6 Transcription Without Recording

Phone endpoint interactions are transcribed, not recorded. `SFSpeechRecognizer` converts the audio stream to text in real time; the audio is never written to disk. The transcript is the equivalent of PA notes — a written record of what was said, not a copy of the audio itself.

**Legal guidance by jurisdiction** is surfaced when the user installs any phone endpoint plugin:

| Jurisdiction | Transcription | What Majordomo shows |
|---|---|---|
| Federal (US) | One-party consent | "You are a party to this call. Transcription does not require disclosure." |
| CA, CT, FL, IL, MD, MA, MI, MT, NH, OR, PA, WA | All-party consent | "Your state requires all parties to consent to monitoring. Inform the other party that you're using an AI assistant." |
| Canada | Two-party consent (PIPEDA) | "Inform the other party that you're using an AI assistant." |
| EU / UK | GDPR consent required | "Inform the other party and obtain consent before transcribing." |

The user's location (from CoreLocation or manually set in Settings) determines which banner is shown. The agent's opening disclosure — *"I'm an AI assistant calling on behalf of..."* — satisfies the notification requirement in all-party consent jurisdictions when combined with the call center's implicit acceptance by continuing the call.

### 19.7 Useful Endpoint Plugins to Ship or Document

| Plugin | Endpoint type | Address |
|---|---|---|
| Samsung Frame TV | lan | `lan://ssdp:samsung:remote-control` |
| Synology NAS | lan | `lan://<ip>:5000` |
| OctoPrint (3D printer) | lan | `lan://<ip>:80` |
| Plex Media Server | lan | `lan://<ip>:32400` |
| Chase Credit Card Support | phone | `tel:+18004322000` |
| Chase Checking/Savings | phone | `tel:+18005246741` |
| GitHub API | https | `https://api.github.com` |
| Slack API | https | `https://slack.com/api` |
| AP News | rss | `feeds.apnews.com/rss/apf-topnews` |
| BBC World | rss | `feeds.bbci.co.uk/news/world/rss.xml` |
| Wolfram Alpha | https | `api.wolframalpha.com` |

### 19.10 Local Network Device Discovery

LAN endpoint plugins can specify either a fixed IP address or an SSDP/UPnP service type for automatic discovery. Majordomo provides a built-in `lan_discover` tool:

```swift
name: "lan_discover"
description: "Discover devices on the local network via SSDP/UPnP or mDNS.
              Returns device name, IP address, port, and service capabilities."
annotations:
  readOnlyHint: true
  openWorldHint: false  // stays on local network only
```

Input:
```json
{
  "service_type": "string",  // SSDP URN, e.g. "urn:samsung.com:device:RemoteControlReceiver:1"
  "timeout_seconds": 5
}
```

Once discovered, the resolved IP is cached in `UserDefaults`. If the device's IP changes (DHCP reassignment), the plugin re-discovers on next connection failure.

**First-time pairing.** Some local devices (Samsung Frame TV, Apple TV) require physical acceptance of a connection on the device itself. The plugin manifest declares `"pairing": "on-screen"` — Majordomo prompts the user: *"Accept the connection request on your Samsung Frame TV."* The pairing token is stored in Keychain.

---


### 19.8 Authentication

| Type | Mechanism | Storage |
|---|---|---|
| `none` | No auth | — |
| `api_key` | Header or query param | Keychain |
| `bearer` | `Authorization: Bearer <token>` | Keychain |
| `basic` | HTTP Basic Auth | Keychain |
| `oauth2` | `ASWebAuthenticationSession` | Keychain (access + refresh token) |

**OAuth2 uses `ASWebAuthenticationSession`** — Apple's built-in auth framework, the same trusted flow Safari uses. Majordomo never handles credentials directly; the system manages the redirect and token exchange. The user sees a familiar Safari-based auth sheet, not a custom webview. Credentials are stored in Keychain under `app.majordomo.<plugin_id>`. Never written to disk, never logged, never visible in UI after entry.

### 19.9 Network & Communication Permissions

Each endpoint plugin gets a distinct permission row naming the specific address:

> **Call Chase Credit Card Support**
> *Allows your AI assistant to call +1 (800) 432-2000 on your behalf, navigate the phone menu, and transcribe the conversation.*

> **Connect to GitHub**
> *Allows your AI assistant to make requests to api.github.com using your access token.*

Majordomo enforces endpoint permissions at the protocol level — a phone plugin can only call its declared number, an HTTPS plugin can only reach its declared domain.

---

## 20. Proactive Monitoring & Daily Brief

---

## 20. Proactive Monitoring & Daily Brief

### 20.1 Philosophy

Majordomo does not replicate Apple's existing notification and scheduling infrastructure. Reminders, Calendar alerts, Focus mode, travel time warnings, and Do Not Disturb are already well-solved. Majordomo's proactive features occupy a distinct space: **cross-system AI reasoning that Apple cannot do natively**.

The filter for every built-in routine: does completing this task require synthesizing information from multiple sources, applying judgment, or taking action across systems in a way that a fixed rule cannot? If a Shortcut or a Calendar alert can do it, Majordomo should not.

Majordomo does not implement its own scheduler. Scheduling intelligence belongs to the AI layer — Claude's scheduled tasks run on a defined cadence, invoke Majordomo tools to gather context, compose a response, and deliver it via `brief_deliver`. Majordomo stores the result and surfaces it on demand.

### 20.2 How It Works

```
Claude.ai Scheduled Task
    │
    │  MCP tool calls
    ▼
Majordomo gathers context across systems
    │
    │  Claude composes the brief
    ▼
brief_deliver → stored locally
    ├── Spoken (if Voice active)
    ├── System notification
    └── Brief panel in UI (accessible any time)
```

### 20.3 `brief_deliver` Tool

```swift
name: "brief_deliver"
description: "Deliver a completed brief to Majordomo for local storage and 
              presentation. Call this at the end of any scheduled task that 
              produces a summary for the user."
annotations:
  readOnlyHint: false
  destructiveHint: false
  openWorldHint: false
```

Input schema:

```json
{
  "title":   { "type": "string", "description": "Short title shown in the Brief panel." },
  "content": { "type": "string", "description": "Full brief in Markdown." },
  "spoken":  { "type": "string", "description": "Condensed version for TTS. Written to be heard, not read. No markdown, full sentences, times as words." },
  "priority":{ "type": "string", "enum": ["normal", "urgent"], "default": "normal" }
}
```

### 20.4 Brief Storage & UI

Briefs are stored in `~/Library/Application Support/app.majordomo/briefs/` as Markdown files. Default retention: 30 briefs (configurable in Settings → Logs).

The Brief panel is a collapsible card anchored above the tab bar in the Majordomo window. It shows the most recent brief title, a relative timestamp, and a one-line summary. Expand to read the full content. **▶ Read aloud** speaks it via `AVSpeechSynthesizer` on demand. The card persists until dismissed — it does not auto-collapse.

### 20.5 Built-In Routines

These are the routines that ship pre-configured in Majordomo's **Routines** settings panel. Each is off by default. Toggling one on registers the corresponding Claude scheduled task. The user configures the time; Majordomo handles the rest.

Each routine passes only because it clears the filter: it requires AI reasoning across multiple systems that Apple's built-in tools cannot perform.

---

**Morning Brief**
*Daily, configurable time (default 7 AM weekdays)*

Synthesizes calendar events for the day, reminders due today, overnight email and messages ranked by importance, current weather from the API plugin, and home state from HomeKit into a single spoken narrative. The value is the synthesis — not any individual data point, but the judgement about what matters this morning and in what order.

---

**Meeting Prep Brief**
*N minutes before each calendar event with attendees (default 10 min)*

Before each meeting, Majordomo searches Spotlight for files sharing keywords with the event title, reads the event's notes and location, pulls attendee details from Contacts, and checks if there are any recent emails from attendees. Claude assembles this into a one-minute brief: who's in the room, what it's about, and what to have ready. Apple's Calendar can alert you that a meeting is starting. It cannot brief you on who you're meeting with.

---

**Overnight Digest**
*Morning, included in the Morning Brief or delivered separately*

Ranks email and messages received overnight by likely importance. Not a count — a judgement. "Three emails you probably need to read: one from your accountant, one from your landlord, one from the school." Apple Mail shows all email in chronological order. This surfaces what matters.

---

**End-of-Day Wrap-up**
*Weekdays, configurable time (default 6 PM)*

Compares what was scheduled against what actually happened — meetings attended, tasks completed, emails sent. Surfaces what's unresolved and what's first tomorrow. The gap between "what the calendar said would happen" and "what Majordomo observed actually happened" is where this lives. No Apple tool tracks this gap.

---

**Weekly Preview**
*Sunday evening, configurable time (default 7 PM)*

Reviews the coming week: identifies days with back-to-back meetings, flags events that need preparation, surfaces conflicts that Calendar shows but doesn't resolve, and notes anything time-sensitive in the next seven days. Delivered as a brief. The goal is to surface preparation work before Monday morning, not during it.

---

**Light Day Suggestion**
*Triggered when calendar has ≥ 3 unscheduled hours before 3 PM*

When the day is genuinely open, the agent suggests what to work on — drawn from outstanding reminders, deferred tasks, and context about current projects. "You have a light morning. The Henderson proposal has been in your reminders for a week and nothing is blocking it." Apple can see the empty calendar. It cannot see the proposal.

---

**Calendar Conflict Resolution**
*Triggered when a new event is added that overlaps an existing one*

When a conflict is detected, the agent doesn't just flag it — it proposes a resolution. It looks at both events, their attendees, their lead times for rescheduling, and suggests which one to move and offers to send the reschedule. Apple Calendar shows the overlap in red. Majordomo resolves it.

---

### 20.6 Routines Settings Panel

```
ROUTINES

Morning Brief              [On]   7:00 AM weekdays     [Edit]
Meeting Prep               [Off]  10 min before events  [Edit]
Overnight Digest           [On]   Included in brief     [Edit]
End-of-Day Wrap-up         [Off]  6:00 PM weekdays      [Edit]
Weekly Preview             [Off]  Sunday 7:00 PM        [Edit]
Light Day Suggestion       [Off]  When triggered        [Edit]
Calendar Conflict Resolve  [On]   When triggered        [Edit]
```

The Edit button opens the corresponding Claude.ai scheduled task for customisation — deeplink into Claude's task management UI.

### 20.7 Event-Driven Local Watchers

For events that cannot wait for a scheduled brief, Majordomo implements lightweight local watchers that call `brief_deliver` directly without involving Claude:

| Trigger | Mechanism | Example |
|---|---|---|
| HomeKit threshold | `HMAccessoryDelegate` | Front door unlocked after 10 PM → spoken alert |
| Calendar imminent | `EKEventStore` | Meeting starts in 2 minutes → brief delivered |
| File changed | `FSEventStream` | Watched folder receives a file → notification |

These produce fixed-text alerts, not AI-composed briefs. They exist for genuinely time-critical events where latency matters more than intelligence.

### 20.8 Coworker Prompt Addition

```
DELIVERING BRIEFS
- At the end of any scheduled or multi-tool task that produces a summary,
  always call brief_deliver with the finished content.
- The spoken field should be written to be heard, not read. No markdown.
  Use full sentences. Read times as words: "nine AM", not "9:00 AM".
- Urgent priority is for information that requires immediate action —
  an unlocked door, a missed appointment, a critical message.
- Open the brief with the most time-sensitive item, not a greeting.
- A brief that takes more than 90 seconds to read aloud is too long.
```

---

## 21. Apple Native Data Sources

These frameworks provide rich, structured data via Apple's own APIs — no third-party service, no API key, no rate limit. Each integrates naturally with the permission model already in place.

### 21.1 WeatherKit

Current conditions, hourly and daily forecasts, severe weather alerts, and historical data via Apple's weather service — the same data as the system Weather app. Requires the `com.apple.developer.weatherkit` entitlement (free tier available, granted via Developer portal).

| Tool | What it gives |
|---|---|
| `weather_current` | Temperature, conditions, wind, humidity, UV index |
| `weather_forecast_hourly` | Hour-by-hour forecast for the next 24 hours |
| `weather_forecast_daily` | Day-by-day forecast for the next 10 days |
| `weather_alerts` | Active severe weather alerts for a location |

Permission row: **"Check the weather"** — *Sends your location to Apple's weather service. Apple does not store it beyond the request.*

### 21.2 MapKit

`MKLocalSearch` returns nearby businesses, POIs, hours, and ratings. `MKDirections` returns real ETAs by driving, walking, or transit. Makes the Meeting Prep brief meaningful — the agent knows how far the next meeting is, not just when it starts.

| Tool | What it gives |
|---|---|
| `maps_search_nearby` | Businesses and POIs within a radius, with hours and ratings |
| `maps_travel_time` | ETA between two addresses by driving, walking, or transit |
| `maps_geocode` | Address to coordinates and vice versa |
| `maps_open` | Opens Maps.app to a location or route |

No entitlement required. Uses CoreLocation (already permitted via location permission row).

### 21.3 HealthKit

Steps, sleep analysis, heart rate, activity rings, workouts, mindfulness minutes. Gated entitlement — Apple grants on review of use case description, similar to HomeKit.

| Tool | What it gives |
|---|---|
| `health_get_steps` | Today's steps and 7-day average |
| `health_get_sleep` | Last night's duration and quality score |
| `health_get_activity` | Move, exercise, and stand ring status |
| `health_get_heart_rate` | Resting heart rate and recent readings |
| `health_get_workouts` | Recent workouts with type, duration, calories |

Permission row: **"Read your health data"** — *Reads activity and sleep data from the Health app. You control exactly which categories are shared.*

### 21.4 PhotoKit

Search and query the Photos library by date, location, people (via Photos' on-device ML), and smart albums. Discrete permission — does not require Full Disk Access.

| Tool | What it gives |
|---|---|
| `photos_search` | Query by date, location, person, or keyword |
| `photos_get_recent` | Most recent N photos with metadata |
| `photos_list_albums` | All albums including smart albums and Memories |
| `photos_get_metadata` | EXIF, location, and people tags for a specific asset |

Permission row: **"Search your photo library"** — *Searches and retrieves photos. Cannot modify or delete photos.*

### 21.5 PDFKit + Vision

PDFKit extracts text from PDFs natively. Vision adds on-device OCR via Apple Neural Engine for scanned documents and image-based text. The agent can read a contract, receipt, invoice, or business card without any network call.

| Tool | What it gives |
|---|---|
| `document_read_pdf` | Extract full text and structure from a PDF |
| `document_ocr_image` | OCR an image file, returns extracted text |
| `document_ocr_pdf` | OCR a scanned (image-only) PDF |
| `document_read_qr` | Decode QR or barcode from an image |

No special entitlement. Uses Full Disk Access for files outside the container (already in tool inventory).

### 21.6 IOKit / System Diagnostics

Battery state, thermal pressure, storage, and connected peripherals. Additions to the Section 7 System tools.

| Tool | What it gives |
|---|---|
| `system_get_battery` | Charge percentage, charging state, time remaining |
| `system_get_storage` | Available and total space per mounted volume |
| `system_get_thermal` | Thermal pressure: nominal / fair / serious / critical |
| `system_get_connected_devices` | USB, Thunderbolt, and Bluetooth peripherals |

No entitlement required.

### 21.7 Natural Language Framework

On-device NLP — language detection, named entity recognition, sentiment analysis. No network call, runs on Apple Neural Engine. Most useful as a preprocessing step before the agent decides how urgently to surface content.

| Tool | What it gives |
|---|---|
| `nlp_sentiment` | Positive / negative / neutral score |
| `nlp_extract_entities` | People, places, organisations, dates from text |
| `nlp_detect_language` | BCP-47 language code |

No entitlement required.

### 21.8 CoreBluetooth + Network Status

| Tool | What it gives |
|---|---|
| `bluetooth_list_connected` | Connected Bluetooth device names and types |
| `network_get_status` | Interface type (WiFi/Ethernet), SSID, VPN active |

### 21.9 Translation Framework (macOS 15+)

Apple's `Translation.framework` provides on-device translation for dozens of language pairs with no network call, no API key, and no data leaving the device. This is the right implementation for any translation task — the privacy and performance properties are better than any cloud service.

| Tool | What it gives |
|---|---|
| `translate_text` | Translate text between any supported language pair |
| `translate_detect_language` | Identify the language of a text (distinct from NLP language detection — uses Translation's model) |

Combined with the Natural Language framework's `nlp_detect_language`, this enables a complete on-device translation pipeline: detect the language of an incoming email, translate it to the user's preferred language for reading, draft a response in the user's language, translate the response for sending. No data ever leaves the Mac.

Permission row: **"Translate text"** — *Translates text between languages entirely on your device. Nothing is sent to Apple or any translation service.*

Language model downloads are handled by the system on first use per language pair, consistent with how the system manages other on-demand resources.

### 21.10 CoreML + Create ML

For any ML inference task — image classification, text classification, feature extraction — CoreML runs models on the Apple Neural Engine. On-device, private, fast.

Majordomo ships with a small set of CoreML models bundled for common tasks:

| Model | Use |
|---|---|
| `MobileNetV2` | Image classification (what is this object?) |
| `SentimentClassifier` | Supplement to `nlp_sentiment` for domain-specific text |

Plugin authors can bundle additional CoreML models in their `.majordomo-plugin` directory. Majordomo loads them at plugin activation and exposes `coreml_infer(model:, input:)` as a generic inference tool scoped to that plugin.

### 21.11 Gated Entitlements Summary

| Framework | Entitlement | Notes |
|---|---|---|
| WeatherKit | `com.apple.developer.weatherkit` | Standard Developer portal request |
| HealthKit | `com.apple.developer.healthkit` | Requires use case description |

Majordomo does not use HomeKit.framework and does not require the HomeKit entitlement. Smart home control uses direct Matter via the bundled `connectedhomeip` SDK. See Section 18.


### 21.12 Camera — AVFoundation

`AVCaptureSession` provides access to any camera connected to the Mac — built-in FaceTime camera, USB webcams, and Continuity Camera (iPhone used as webcam via macOS 26). The agent can capture a single frame from any camera and receive it as an image content block in the tool response — the same format as sending the agent a photo.

**Primary use case: visual confirmation.** After any physical automation action — SwitchBot press, IR command, Bluetooth trigger — the agent can capture a frame from the nearest camera and confirm whether the action succeeded. This closes the feedback loop for devices that have no digital state channel.

| Tool | What it gives |
|---|---|
| `camera_list` | All connected cameras with names and types (built-in, USB, Continuity) |
| `camera_capture_frame` | Single JPEG frame from a named camera, returned as MCP image block |
| `camera_capture_burst` | N frames over T seconds, returned as sequence of image blocks |
| `camera_watch_for_change` | Monitor a camera region until visual change is detected; return the frame |

**`camera_capture_frame` response format:**

```json
{
  "content": [
    {
      "type": "image",
      "data": "<base64_jpeg>",
      "mimeType": "image/jpeg"
    },
    {
      "type": "text",
      "text": "Living Room Camera · 2026-04-02T20:15:33Z · 1920×1080"
    }
  ]
}
```

The agent receives the image natively and can describe, analyze, or answer questions about it.

**`camera_watch_for_change` — polling with early exit:**

```swift
name: "camera_watch_for_change"
description: "Capture frames from a camera region at intervals until significant 
              visual change is detected or timeout is reached. Returns the 
              before/after frames. Use this to confirm physical state changes 
              without knowing exactly when they will complete."
```

Input schema:

```json
{
  "camera":           { "type": "string",  "description": "Camera name from camera_list" },
  "region":           { "type": "object",  "description": "Optional crop: {x, y, width, height} as 0–1 fractions" },
  "interval_seconds": { "type": "number",  "default": 1.0 },
  "timeout_seconds":  { "type": "integer", "default": 30 },
  "change_threshold": { "type": "number",  "default": 0.05,
                        "description": "Fraction of pixels that must change to trigger. 0.05 = 5%." }
}
```

Returns the baseline frame and the changed frame side by side so the agent can describe what changed.

**Region of interest.** The optional `region` parameter crops the frame before analysis. For a fireplace in the lower-right quadrant of the frame:

```json
"region": { "x": 0.5, "y": 0.5, "width": 0.5, "height": 0.5 }
```

Smaller regions reduce token usage and focus the agent's attention. The user can say "the fireplace is in the bottom right of the living room camera" and the agent writes that to the user profile — no future configuration needed.

**Named camera positions.** The user profile stores camera-to-location associations:

```markdown
## Camera positions
- "Living Room Camera" covers the fireplace area (bottom right), the sofa, and the front door.
- "Kitchen Camera" covers the stovetop and the sink.
```

The agent reads this before any camera operation and selects the right camera without asking.

Permission row: **"Use your camera"** — *Allows your AI agent to capture still frames from connected cameras to confirm physical actions. Frames are analyzed immediately and not stored unless you ask.*

**Coworker prompt addition:**

```
VISUAL CONFIRMATION
- After any physical automation action where success cannot be confirmed 
  from device state alone, offer to verify visually: "Want me to check 
  the camera to confirm it worked?"
- If the user says yes or has pre-authorized visual confirmation for this 
  device, call camera_capture_frame with the relevant camera and region.
- Wait at least 3 seconds after the action before capturing — give 
  physics time to catch up.
- For actions with uncertain timing (SwitchBot press, IR command), use 
  camera_watch_for_change with a 15–30 second timeout rather than a 
  fixed delay.
- Describe what you see plainly: "The flame is lit" or "The logs are 
  dark — the fireplace doesn't appear to be on." Don't hedge with 
  "it looks like" if the visual is clear.
- If the image is ambiguous, say so and offer to try again or ask the 
  user to check manually.
- Never store frames. Analyze and discard.
```

---



### 22.1 Purpose

A Skill is user-specific procedural knowledge: how *this* user does *this* task, written in a form the agent can follow and improve over time. Skills are distinct from every other knowledge structure in Majordomo:

| Concept | What it is |
|---|---|
| Script | A recorded sequence of MCP tool calls |
| Coach prompt | Domain expertise about an app |
| User profile | Who the user is and how they prefer to work |
| **Skill** | How this user does a specific task, step by step |

A skill might be "How I process invoices at month-end", "How to deploy to production", or "The way I structure my weekly review". It may involve steps the agent can automate, steps the user must do manually, and judgment calls the agent needs to understand.

Skills are Markdown documents, editable directly by the user or by the agent. They live in `~/Library/Application Support/app.majordomo/skills/` and are available as MCP resources. The agent can fetch them on demand, be directed to follow one, or be asked to improve one after a task.

### 22.2 Creation Modes

Skills are created in three ways. All three produce the same output: a named Markdown file the user can read, edit, and refine.

---

**Observe mode** — the agent watches the user work and drafts instructions from what it sees.

The user taps **Record** in the Skills tab. Majordomo activates two observers simultaneously:

- `AXObserver` watching for UI events on all running applications — button clicks, menu selections, text field edits, window focus changes
- `ScreenCaptureKit` taking a screenshot on each significant event

The agent receives a stream of events like:
```
[09:14:22] Focused: Safari — window "Vendor Invoice #4421 - PDF"
[09:14:31] Clicked: Button "Download" in Safari toolbar
[09:14:35] Focused: Finder — "Downloads" folder
[09:14:38] Moved file: "Invoice_4421.pdf" → "~/Documents/Invoices/2026/April/"
[09:14:52] Opened: Preview — "Invoice_4421.pdf"
[09:15:04] Clicked: Menu "File > Export as PDF" in Preview
[09:15:11] Typed in text field: "Invoice_4421_processed"
```

Combined with screenshots at each step, the agent drafts:

```markdown
## Processing a Vendor Invoice

1. Open the invoice email in Safari and download the PDF attachment.
2. Move the downloaded PDF from Downloads to ~/Documents/Invoices/YYYY/Month/.
   Name the file Invoice_[number].pdf.
3. Open the PDF in Preview.
4. Export as PDF (File > Export as PDF) with the name Invoice_[number]_processed.
...
```

The user reviews, edits, and saves. The record session can be annotated with voice — anything the user says during recording is transcribed and incorporated as context or notes.

Observe mode requires Accessibility and Screen Recording permissions.

---

**Narrate mode** — the user describes the task aloud while doing it. Voice input is active throughout; the agent transcribes and structures the narration into instructions.

No Accessibility observation. The agent only hears what the user says. Lower fidelity, but works for anything — including tasks that happen outside the Mac (a physical filing process, a phone call workflow, a cooking routine).

The agent asks clarifying questions at the end before drafting:
- "You mentioned checking the vendor against a list — where is that list?"
- "Is step 4 something I can do for you, or do you need to do it yourself?"

---

**Draft mode** — the user describes the task in conversation. The agent asks questions and builds the skill collaboratively. Nothing needs to happen while recording — this is for encoding knowledge the user has but hasn't done yet in front of Majordomo.

This mode is triggered naturally in conversation: "Let me teach you how I handle support escalations." The agent recognises the learning intent and enters a structured question-answer flow.

---

### 22.3 Skill Storage Format

```
~/Library/Application Support/app.majordomo/skills/
    process-invoices.md
    weekly-review.md
    deploy-to-production.md
```

A skill file:

```markdown
---
name: Process vendor invoices
created: 2026-04-03T09:22:00Z
updated: 2026-04-03T09:22:00Z
created_via: observe
tags: [finance, monthly]
agent_can_automate: partial
---

## Process Vendor Invoices

Use this when a vendor invoice arrives that needs to be filed and logged.

### Steps

1. Download the PDF from the invoice email.
2. Move to `~/Documents/Invoices/YYYY/Month/` named `Invoice_[number].pdf`.
3. Open in Preview and export as PDF named `Invoice_[number]_processed`.
4. *(Manual)* Log the invoice in the spreadsheet at `~/Documents/Finance/2026/Invoices.xlsx`
   — enter vendor name, invoice number, amount, due date.
5. *(Agent can do)* Mark the email as read and move it to the "Invoices" mailbox.

### Notes

- The spreadsheet has a template row at the top. Duplicate it for each new entry.
- If the invoice total is over $5,000, also forward to accountant@example.com.

### Agent guidance

Steps 1, 2, 3, and 5 can be automated. Step 4 requires the user to fill in the 
spreadsheet manually. Do not attempt to write to the spreadsheet unless the user 
explicitly asks.
```

The front matter is machine-readable. The body is human-readable and editable. The `Agent guidance` section is where the user and agent negotiate what can be automated versus what stays manual.

### 22.4 Skill Tools

| Tool | Description | readOnly |
|---|---|---|
| `skill_list` | Returns all skills with name, tags, and creation date | ✅ |
| `skill_get` | Returns full content of a named skill | ✅ |
| `skill_create` | Creates a new skill with name and content | ❌ |
| `skill_update` | Updates skill content (full replace or diff patch) | ❌ |
| `skill_delete` | Deletes a skill | ❌ |
| `skill_record_start` | Starts an observe-mode recording session | ❌ |
| `skill_record_stop` | Stops recording and returns the event log for drafting | ❌ |
| `skill_suggest` | Returns skills whose names or tags match the current task description | ✅ |

### 22.5 Agent Behaviour

The `macos-coworker` prompt addition:

```
SKILLS
- Before starting any multi-step task, call skill_suggest to check whether 
  the user has documented a preferred way of doing it. If a matching skill 
  exists, read it with skill_get and follow it unless the user says otherwise.
- When completing a task that took more than 3 tool calls and no skill exists 
  for it, offer to save it: "Want me to save that as a skill so I can follow 
  the same steps next time?"
- When a skill step says "(Manual)", tell the user what needs doing and wait 
  for them to complete it before continuing.
- After using a skill, ask if it needs updating: "That step 4 took longer than 
  usual — want me to add a note about that?"
- When recording in Observe mode, do not narrate or ask questions during the 
  session. Observe silently. Ask questions only after the user stops recording.
```

### 22.6 Skill Refinement Over Time

Skills are living documents. Every time an agent uses a skill, it can propose edits:

- A step that consistently fails → agent adds a troubleshooting note
- A step that's been automated → agent updates the `Agent guidance` section
- A step the user skips every time → agent marks it as optional or removes it
- A new faster path discovered → agent proposes an updated version

Updates are proposed as diffs shown in the swift-markdown editor before applying. The user approves each change — the skill doesn't update silently.

### 22.7 Skills Tab

The main window gains a fifth tab: **Skills**.

**Skill list.** Each row shows:
- Skill name
- Tag pills (finance, monthly, etc.)
- Created via badge: `observed` / `narrated` / `drafted`
- `agent_can_automate` indicator: Full / Partial / Manual only
- Last used timestamp
- ··· menu → Edit · Duplicate · Delete

**Record button.** A prominent **● Record** button opens the recording mode picker: Observe / Narrate / Draft. Starts the session immediately on selection.

**Empty state:** *"Skills are things you know how to do. Tap Record and show Majordomo how you do something — it will write the instructions and remember them for next time."*

**Edit view.** Tapping a skill opens it in the swift-markdown editor, same as the prompt editors. The front matter is shown as a structured form (name, tags, automation level) above the Markdown body.

### 22.8 Community Skills Registry

The community registry at `majordomo-mcp/plugins` gains a `skills/` subdirectory for shareable skills. Unlike plugins, skills are generic Markdown documents with no code — they can be shared directly as `.md` files. Installing a community skill is a drag-and-drop into the Skills tab.

---

## 23. Phone Calls

Phone call automation is handled by the `phone` endpoint type in the Endpoint Plugin system (Section 19). See Section 19 for the full technical specification including Continuity Calls architecture, IVR navigation, DTMF tools, and the "on behalf of" ethical framework.

This section captures the interaction design specific to phone calls that sits above the plugin layer.

### 23.1 Three Modes

| Mode | Trigger | Who speaks |
|---|---|---|
| **IVR Navigator** | Automated menu system | Agent navigates automatically via DTMF |
| **On Behalf Of** | Human call center agent | Agent speaks, identified as AI assistant |
| **Copilot** | Human call center agent, user present | User speaks; agent transcribes and assists |

The user chooses the default mode per phone endpoint plugin in Settings. The agent can switch modes mid-call — for example, starting in "On Behalf Of" and handing to Copilot when identity verification is required.

### 23.2 Call HUD

A minimal overlay activates during any active call:

```
┌─────────────────────────────────────────────────────────┐
│  🔴 LIVE  Chase Credit Card Support  •  4:23            │
├─────────────────────────────────────────────────────────┤
│  Agent: "Can I get the last four digits of your card?"  │
│  You:   "—"                                             │
│                                                         │
│  💡  Card ending in 4821                                │
│  💡  Account open since March 2019                      │
│                                                         │
│  Suggested: "The last four are 4821."                   │
├─────────────────────────────────────────────────────────┤
│  [Mute]  [Hold]  [End Call]  [Take Note]                │
└─────────────────────────────────────────────────────────┘
```

Information cards are pulled automatically from Contacts, user-defined call skills, and Keychain-stored account references.

### 23.3 Call Skills

Every phone endpoint plugin has a paired skill document (Section 22) that captures the IVR tree, known tips, what to have ready, and what to say to the human agent. GetHuman.com is in the Trusted Sources list by default so the agent can pull current IVR paths before any call.

### 23.4 Post-Call Summary

After every call, the agent delivers a summary via `brief_deliver`:
- Purpose of the call
- What was resolved
- Reference numbers and confirmation codes
- Agent name and any commitments made
- Follow-up actions required

---

## 24. Image Tools

### 24.1 Purpose

Several workflows require preparing images before they can be used: uploading to a Frame TV, generating a custom greeting card, preparing a photo for a contact. Core Image and ImageIO handle all of this natively on macOS — no third-party library, no network call.

### 24.2 Image Preparation Tools

| Tool | What it does | Framework |
|---|---|---|
| `image_resize` | Resize to exact dimensions or within a bounding box | Core Image |
| `image_convert` | Convert between JPEG, PNG, HEIC, TIFF, WebP | ImageIO |
| `image_set_color_profile` | Assign or convert color profile (sRGB, P3, AdobeRGB) | Core Image |
| `image_crop` | Crop to a specific region or aspect ratio | Core Image |
| `image_get_info` | Returns dimensions, color profile, format, file size | ImageIO |
| `image_compose` | Overlay text or another image (for watermarks, captions) | Core Image |

Input and output are file paths. The tools write to a temp directory by default; the caller specifies the final destination.

### 24.3 Frame TV Preparation

The Samsung Frame TV requires specific image specs that vary by model. The Frame TV plugin declares these as `image_requirements` in its manifest:

```json
"image_requirements": {
  "width": 3840,
  "height": 2160,
  "format": "jpeg",
  "color_profile": "sRGB",
  "max_file_size_mb": 20
}
```

When the agent calls a Frame TV upload tool, Majordomo automatically runs the image through `image_resize`, `image_convert`, and `image_set_color_profile` in sequence if the source image doesn't already meet requirements. The user is informed what was done: *"Resized from 5472×3648 to 3840×2160 and converted to sRGB JPEG."*

---

## 25. AI Art Generation

### 25.1 Purpose

If Majordomo can reach the Frame TV and prepare images, the natural completion is generating the art itself. *"Put a watercolor of the Santa Cruz coastline on the living room TV"* should work end-to-end.

### 25.2 Generation Path

```
User: "Generate a woodblock print of Mount Tamalpais at dusk 
       and display it on the living room TV."

Agent:
1. art_generate(prompt, style, dimensions)     → image file
2. image_resize + image_convert                → TV-ready JPEG
3. frame_tv_upload(image_path)                → uploaded to TV
4. frame_tv_select_art(image_id)              → displayed
```

### 25.3 Generation Sources

Art generation follows the Apple-first principle. Local generation on Apple Silicon is the default; cloud generation is an optional endpoint plugin for users who want it.

| Option | Provider | Privacy | Cost | How |
|---|---|---|---|---|
| **Apple Neural Engine (default)** | `ml-stable-diffusion` (Apple open-source) | ✅ On-device | Free | Swift Package compiled in |
| DALL-E 3 | OpenAI API (plugin) | ☁ Cloud | Per image | Endpoint plugin |
| Ideogram | ideogram.ai (plugin) | ☁ Cloud | Per image | Endpoint plugin |

`ml-stable-diffusion` is Apple's open-source Swift package for running Stable Diffusion models on Apple Silicon. It uses Core ML and the Apple Neural Engine — the same hardware path as on-device image classification, speech recognition, and translation. Models are downloaded on first use and cached locally. No API key. No network call at inference time.

```swift
// Apple-first art generation via ml-stable-diffusion SPM dependency
let pipeline = try StableDiffusionPipeline(resourcesAt: modelURL)
let images = try pipeline.generateImages(
    prompt: "woodblock print of Mount Tamalpais at dusk",
    imageCount: 1,
    seed: 42
)
```

Cloud generation plugins are available for users who need higher resolution, specific styles not achievable locally, or faster generation on older hardware. They follow the standard Endpoint Plugin `https` pattern with the user's API key stored in Keychain.

### 25.4 `art_generate` Tool

Exposed by any art generation endpoint plugin:

```swift
name: "art_generate"
description: "Generate an image from a text description. Returns a local file path.
              Specify style, dimensions, and quality to match your target display."
```

Input schema:
```json
{
  "prompt":     { "type": "string", "description": "What to generate." },
  "style":      { "type": "string", "description": "e.g. 'woodblock print', 'oil painting', 'watercolor', 'photograph'" },
  "width":      { "type": "integer", "default": 3840 },
  "height":     { "type": "integer", "default": 2160 },
  "provider":   { "type": "string", "description": "Which generation plugin to use if multiple are installed." }
}
```

### 25.5 Non-HomeKit Device Plugins: Worked Examples

The following manifests demonstrate the same pattern across four different device categories. Each is a community-contributed plugin installable via the Plugins tab.

---

**Samsung Frame TV** (Section 24 image requirements apply)

```json
{
  "name": "Samsung Frame TV",
  "id": "com.samsung.frametv.majordomo-plugin",
  "type": "endpoint",
  "version": "1.0.0",
  "tool_prefix": "frame_tv",
  "description": "Control art mode on Samsung Frame TV — upload, select, generate artwork.",

  "endpoint": {
    "type": "lan-ws",
    "port": 8002,
    "discovery": { "method": "ssdp", "service_type": "urn:samsung.com:device:RemoteControlReceiver:1" },
    "pairing":   { "method": "on-screen", "instructions": "Select 'Allow' on your Frame TV when prompted." },
    "state":     { "method": "websocket-push" }
  },

  "capabilities": {
    "power":    { "type": "boolean" },
    "input":    { "type": "string", "enum": ["tv", "hdmi1", "hdmi2", "art"] },
    "art_mode": { "type": "boolean" }
  },

  "image_requirements": {
    "width": 3840, "height": 2160, "format": "jpeg",
    "color_profile": "sRGB", "max_file_size_mb": 20
  },

  "tools": [
    { "name": "frame_tv_list_art",   "description": "List all artwork stored on the TV." },
    { "name": "frame_tv_upload",     "description": "Upload an image as new artwork. Auto-prepares to spec." },
    { "name": "frame_tv_select_art", "description": "Set which artwork is currently displayed." },
    { "name": "frame_tv_delete_art", "description": "Remove artwork by ID." }
  ],

  "prompts": [
    { "type": "coworker", "file": "prompts/coworker.md" },
    { "type": "coach", "name": "art-curation", "label": "Art & Display", "file": "prompts/coach-art.md", "default": true }
  ]
}
```

---

**Sonos** (speaker system, HTTP REST on local network)

```json
{
  "name": "Sonos",
  "id": "com.sonos.majordomo-plugin",
  "type": "endpoint",
  "version": "1.0.0",
  "tool_prefix": "sonos",
  "description": "Control Sonos speakers — play, pause, volume, grouping, playlists.",

  "endpoint": {
    "type": "lan-http",
    "port": 1400,
    "discovery": { "method": "ssdp", "service_type": "urn:schemas-upnp-org:device:ZonePlayer:1" },
    "pairing":   { "method": "none" },
    "state":     { "method": "poll", "interval_seconds": 10, "endpoint": "/status/topology" }
  },

  "capabilities": {
    "power":   { "type": "boolean" },
    "volume":  { "type": "integer", "min": 0, "max": 100 },
    "mute":    { "type": "boolean" },
    "playing": { "type": "boolean" },
    "track":   { "type": "string", "readonly": true }
  },

  "tools": [
    { "name": "sonos_list_rooms",    "description": "List all Sonos speakers and groups by room." },
    { "name": "sonos_play_playlist", "description": "Play a named Sonos or Spotify playlist in a room." },
    { "name": "sonos_group_rooms",   "description": "Group multiple rooms to play the same audio." },
    { "name": "sonos_ungroup",       "description": "Return a room to independent playback." }
  ],

  "prompts": [
    { "type": "coworker", "file": "prompts/coworker.md" },
    { "type": "coach", "name": "audio",   "label": "Music & Audio",    "file": "prompts/coach-audio.md",   "default": true },
    { "type": "coach", "name": "ambience","label": "Ambience & Scenes", "file": "prompts/coach-ambience.md" }
  ]
}
```

---

**Roku** (streaming device, UDP External Control Protocol)

```json
{
  "name": "Roku",
  "id": "com.roku.majordomo-plugin",
  "type": "endpoint",
  "version": "1.0.0",
  "tool_prefix": "roku",
  "description": "Control Roku — launch apps, navigate, search, playback control.",

  "endpoint": {
    "type": "lan-http",
    "port": 8060,
    "discovery": { "method": "ssdp", "service_type": "roku:ecp" },
    "pairing":   { "method": "none" },
    "state":     { "method": "poll", "interval_seconds": 5, "endpoint": "/query/active-app" }
  },

  "capabilities": {
    "power":   { "type": "boolean" },
    "volume":  { "type": "integer", "min": 0, "max": 100 },
    "mute":    { "type": "boolean" },
    "playing": { "type": "boolean" }
  },

  "tools": [
    { "name": "roku_list_apps",   "description": "List installed streaming apps (Netflix, HBO, etc.)." },
    { "name": "roku_launch_app",  "description": "Launch an app by name or ID." },
    { "name": "roku_search",      "description": "Search across all apps for a title." },
    { "name": "roku_keypress",    "description": "Send a remote keypress (home, back, select, etc.)." }
  ],

  "prompts": [
    { "type": "coworker", "file": "prompts/coworker.md" },
    { "type": "coach", "name": "streaming", "label": "Streaming & Entertainment", "file": "prompts/coach.md", "default": true }
  ]
}
```

---

**Philips Hue** (non-HomeKit, HTTP via local Bridge)

```json
{
  "name": "Philips Hue",
  "id": "com.philips.hue.majordomo-plugin",
  "type": "endpoint",
  "version": "1.0.0",
  "tool_prefix": "hue",
  "description": "Control Philips Hue lights via local Bridge — on/off, color, scenes, rooms.",

  "endpoint": {
    "type": "lan-http",
    "port": 80,
    "discovery": { "method": "mdns", "service_type": "_hue._tcp" },
    "pairing": {
      "method": "on-screen",
      "instructions": "Press the button on top of your Hue Bridge within 30 seconds."
    },
    "state": { "method": "poll", "interval_seconds": 30, "endpoint": "/api/{token}/lights" }
  },

  "capabilities": {
    "power":      { "type": "boolean" },
    "brightness": { "type": "integer", "min": 0, "max": 100 },
    "color":      { "type": "object",  "properties": { "hue": {}, "saturation": {}, "kelvin": {} } }
  },

  "tools": [
    { "name": "hue_list_lights",   "description": "List all lights with current state." },
    { "name": "hue_list_rooms",    "description": "List rooms/zones with their lights." },
    { "name": "hue_activate_scene","description": "Activate a named scene in a room." },
    { "name": "hue_set_room",      "description": "Set all lights in a room to a color/brightness." }
  ],

  "prompts": [
    { "type": "coworker", "file": "prompts/coworker.md" },
    { "type": "coach", "name": "lighting", "label": "Lighting & Atmosphere", "file": "prompts/coach.md", "default": true }
  ]
}
```

---

These four examples cover the full range of LAN endpoint patterns:

| Dimension | Frame TV | Sonos | Roku | Hue |
|---|---|---|---|---|
| Protocol | WebSocket | HTTP | HTTP | HTTP |
| Discovery | SSDP | SSDP | SSDP | mDNS |
| Pairing | On-screen | None | None | Physical button |
| State | Push | Poll | Poll | Poll |
| Custom tools | Yes (art) | Yes (grouping) | Yes (app list) | Yes (scenes) |
| Image requirements | Yes | No | No | No |

Any non-HomeKit/Matter device follows this same pattern. The community registry's device category becomes the primary destination for smart home products that Apple hasn't absorbed — which remains the majority of the market.

## 26. Multi-User Context

### 26.1 Philosophy

Majordomo runs on behalf of one user but affects shared environments. Apple already provides two multi-user permission substrates — iCloud Family Sharing for households and Apple Business Manager for workplaces. Majordomo integrates with both rather than building its own multi-user architecture.

### 26.2 iCloud Family — Household Context

iCloud Family Sharing provides a CloudKit container accessible to up to six family members. Majordomo uses `CKContainer` with `CKDatabase(scope: .shared)` to publish household-affecting automations and state changes to a family-visible zone.

**When Majordomo notifies the household:**
- A new automation is created that affects shared devices (windows, locks, thermostats, shared rooms)
- An existing automation is modified or deleted
- A shared device enters an error or unexpected state ("Kitchen shade failed to close — still open")

**Notification mechanism.** Majordomo writes a structured record to the shared CloudKit zone. Each family member's Majordomo instance receives a `CKQuerySubscription` notification, which surfaces as a macOS notification and a line in the Brief panel:

> *"David created a new automation: Kitchen West Windows close 90 minutes before sunset daily."*

Family members can dismiss, comment, or ask their own Majordomo instance to modify the automation if they're the organizer.

**Organizer elevation.** The iCloud Family organizer has elevated permissions in Majordomo's household context — they can create automations affecting shared devices without additional confirmation. Other family members are prompted: *"This affects a shared device. The family organizer will be notified."*

**Tools:**

| Tool | What it does |
|---|---|
| `family_list_members` | Lists iCloud Family members with their notification preferences |
| `family_notify` | Posts a household notification to the shared CloudKit zone |
| `family_list_automations` | Lists automations flagged as household-affecting |

Permission row: **"Notify your household"** — *Allows Majordomo to post automation changes to your iCloud Family group. Family members will see notifications about changes to shared devices.*

### 26.3 Apple Business Manager — Workplace Context

Apple Business Manager (ABM) and Apple Business Essentials (ABE) manage Managed Apple IDs and device enrollment for organisations. Majordomo integrates as a managed application:

**MDM configuration profile.** An IT administrator can deploy a Majordomo configuration profile via ABM that pre-sets:
- The organisation's coworker prompt additions (communication standards, approved tools)
- Permitted plugins (e.g., the organisation's GitHub, Slack, internal tools)
- Blocked tools (e.g., `mail_send` requires manager approval)
- Shared workplace context document (equivalent to the user profile, but organisation-wide)

**Managed shared context.** A read-only `workplace-context.md` MCP resource is deployed via MDM alongside the app. It contains organisation-level facts the agent should know: team structure, communication preferences, approved vendor list, internal systems. Individuals extend this with their own user profile.

**Workplace tools:**

| Tool | What it does |
|---|---|
| `workplace_get_context` | Returns the org-level context document |
| `workplace_list_colleagues` | Organisation directory from Managed Contacts |
| `workplace_shared_calendar` | Access to shared team calendars |

This is not a Majordomo-managed feature — it's Apple's existing MDM infrastructure applied to Majordomo. The app ships with MDM support; the organisation configures it via ABM. Majordomo doesn't run a server or manage accounts.

---

## 27. Skills Preservation

### 27.1 Purpose

Majordomo tracks which capabilities it handles on behalf of the user. After a configurable interval without the user exercising a skill themselves, the agent occasionally offers to step back and let the user handle it — preserving the human capability the agent has been scaffolding.

This is the bicycle principle applied actively. The jet engine is available. The legs still work.

### 27.2 Tracking

Each Skill file (Section 22) gains a `preservation` block in its front matter:

```markdown
---
name: Dispute a credit card charge
tags: [finance, phone]
preservation:
  enabled: true
  agent_handle_count: 34
  user_handle_count: 2
  last_user_handle: 2025-09-12
  threshold_days: 180
  last_offered: 2026-01-15
  user_declined: true
---
```

When `agent_handle_count` is high, `user_handle_count` is low, and more than `threshold_days` have elapsed since the user last did it themselves, the preservation system activates.

### 27.3 The Offer

The offer appears at the natural moment — when the task comes up, before the agent starts:

> "I've handled your Chase disputes 34 times. You haven't done one yourself in about eight months. Want to handle this one? I'll walk you through it."

The offer is made at most once per month per skill. If the user declines once, the counter resets. If they decline twice, `preservation.enabled` is set to false for that skill and it's never offered again.

The agent never frames this as concern. It's not "you should stay practiced for when I'm unavailable." It's "do you want to?" — a genuine offer, easy to decline, with no implied judgment.

### 27.4 Coworker Prompt Addition

```
SKILLS PRESERVATION
- Before handling a task that has a preservation offer pending, surface the 
  offer naturally: "Want to handle this one yourself? I can walk you through it."
- If the user says no, proceed without comment.
- If the user says yes, shift to coach mode: guide them step by step rather 
  than acting for them. Use skill_get to retrieve the documented procedure.
- Never frame the offer as concern about dependency. It's an option, not a warning.
- After a preservation session where the user handles the task themselves, update 
  the skill's user_handle_count and last_user_handle.
```

### 27.5 Skills Preservation Tab Addition

The Skills tab row gains a small indicator when preservation is active for a skill — a subtle "↺" icon next to the skill name, with a tooltip: *"Majordomo will occasionally offer to let you handle this yourself."* Tapping it opens a sheet showing the preservation stats and a toggle to disable.

---



## 29. iCloud Sync

### 29.1 What Syncs

Majordomo stores its user data in an iCloud Drive ubiquity container: `~/Library/Mobile Documents/app.majordomo/`. All files in this container sync automatically across the user's Macs via `NSFilePresenter`. No CloudKit setup, no additional entitlements beyond `com.apple.developer.icloud-container-identifiers`.

| Data | File | Syncs |
|---|---|---|
| Skills | `skills/*.md` | ✅ |
| Scripts | `scripts/callog.json` | ✅ |
| Automations | `automations/*.json` | ✅ |
| User profile | `user-profile.md` | ✅ |
| Camera positions | `camera-positions.md` | ✅ |
| Coworker prompt edits | `prompts/macos-coworker.md` | ✅ |
| Coach prompt edits | `prompts/macos-coach.md` | ✅ |
| Matter fabric credentials | Keychain (syncs via iCloud Keychain) | ✅ |
| Logs | `logs/` | ❌ — device-local only |
| Plugin bundles | `Plugins/` | ❌ — reinstall on each Mac |

Logs are excluded intentionally — they're device-specific records of what happened on that Mac. Plugin bundles are excluded because they may contain architecture-specific compiled code; the user reinstalls plugins from the registry on each machine.

### 29.2 Conflict Resolution

Most files are last-write-wins. The exception is the user profile (`user-profile.md`): if two Macs write to it concurrently, `NSFileCoordinator` merges line-by-line, keeping both additions, flagging true conflicts for the agent to resolve: *"Your profile was edited on two Macs at the same time. I've kept both versions — want me to merge them?"*

### 29.3 iCloud Status

The iCloud sync indicator in the server status strip (Section 9.2) reflects `NSUbiquitousItemDownloadingStatusKey`:

| Status | Indicator | Meaning |
|---|---|---|
| Current | ☁ ✓ | All files synced |
| Uploading | ☁ ↑ | Local changes being uploaded |
| Downloading | ☁ ↓ | Another Mac made changes, downloading |
| Error | ☁ ⚠ | Tap for details |
| Not signed in | (hidden) | iCloud not available |

### 29.4 Privacy Note

User data syncs to iCloud Drive, which is end-to-end encrypted on Apple's servers. The user profile, skills, and automation definitions may contain personal context. The permission row consequence string for iCloud sync reads: *"Your Majordomo data — skills, automations, and preferences — syncs across your Macs via iCloud Drive, encrypted by Apple."*

---

## 30. Plugin Signing and Security

### 30.1 Signing Requirement

All plugins must be signed with an Apple Developer ID. Majordomo verifies the signature of every plugin bundle before loading it. The `manifest.json` must include:

```json
{
  "developer_id": "TEAM1234567",
  "developer_name": "Jane Smith",
  "signed_date": "2026-04-01"
}
```

Majordomo checks the bundle signature against the declared `developer_id` at install time and on each launch. A mismatch prevents loading.

**Unsigned plugins** display a full-screen interstitial before activation:

```
⚠ This plugin is not signed by a verified developer.

Unsigned plugins have not been reviewed and could
damage your files, read your private data, or send
messages without your knowledge.

[ Don't Install ]          [ Install Anyway ]
```

"Install Anyway" requires the user to type "install unsigned" in a confirmation field. This friction is intentional.

### 30.2 Community Registry Policy

The `majordomo-mcp/plugins` GitHub registry only accepts signed plugins. Pull requests from unsigned bundles are rejected automatically by a CI check. The registry displays each plugin's developer name and signing date. Users can report plugins for review.

### 30.3 Plugin Sandbox

Shell scripts within plugins run under a restricted profile:
- No network access beyond the plugin's declared `base_url` or `address`
- No access to `~/Library`, `~/Documents`, or other sensitive directories unless a permission is granted
- No execution of other processes
- Killed after 30 seconds

AppleScript and JXA tools are limited to the declared `target_app` bundle ID. They cannot address other applications.

### 30.4 Supply Chain Warning

Plugin signing raises the bar but does not eliminate supply chain risk. A signed plugin whose developer account is compromised, or whose coworker prompt contains a prompt injection, can still cause harm. The "View Source" requirement before activation remains mandatory. Majordomo ships with a notice in the Plugins tab:

> *"Plugins extend what your AI can do. Review the source before activating. Majordomo verifies that plugins are signed by their declared developer, but cannot verify their intent."*

---



All items that were open questions are now decided.

| # | Topic | Decision |
|---|---|---|
| 1 | v1 scope | All tool domains ship in v1. No deferred phases. |
| 2 | Siri callback | Persistent SSE connection. See Section 15.1. |
| 3 | Multi-client | Client list in Connections tab. Log viewer for transparency. See Section 15. |
| 4 | Prompt ownership | User and agent can both edit via swift-markdown. Spec'd content is the default. See Section 14.2. |
| 5 | Port conflicts | Automatic. Preferred port tried first; OS assigns on conflict. Loopback-only binding (`127.0.0.1`). No Bonjour. Port file for local discovery. Auto-patch for known clients. See Section 14.1. |
| 6 | Skill persistence | Opt-in. Agent reads/writes `user-profile.md` as a plain Markdown MCP resource. See Section 14.3. |
| 7 | Call log privacy | User-configurable retention (default 30 days) and parameter stripping (default on). Exposed in Settings → Logs. See Section 14.4. |