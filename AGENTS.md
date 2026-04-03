# Agents

## Context

- Technical requirements are in docs/technical_requirements_doc.md — always read the relevant TRD section before implementing an issue
- GitHub issues reference TRD sections by number (e.g. "per TRD Section 16")

## Constraints

- Security: use NSEvent.addGlobalMonitorForEvents, NOT CGEventTap — intentional security decision (see TRD 16.3)
- Privacy: all speech recognition must use on-device mode (requiresOnDeviceRecognition = true) — no audio leaves the Mac
- Entitlements: add required entitlements to Majordomo.entitlements AND usage descriptions to project.yml INFOPLIST_KEY_ settings
