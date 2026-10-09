# Companion Architecture

## Product Shape

A Companion is a single native macOS accessory app with two independently controlled surfaces:

```text
CompanionAppDelegate
├── Unified status item and menu
├── DesktopPetCoordinator
│   ├── Character window
│   ├── Work/break/input state
│   ├── Reminders and idle state
│   └── Control/record panels
└── TrackerCoordinator
    ├── Calendar/tracker window
    ├── Domain pipeline
    ├── Local task state
    └── Read-only EventKit adapter
```

Use one process so lifecycle, permissions, cleanup, and menu ownership are unambiguous. The coordinators must not create their own `NSApplication` or status item.

## Module Boundaries

| Component | Owns | Must not own |
|---|---|---|
| App delegate | lifecycle, status menu, cross-feature commands | feature timers, domain persistence |
| Desktop pet | character rendering, drag/resize, work metrics, reminders | Tracker records, calendar writes |
| Tracker | tracker window, tasks, pipelines, read-only calendar | input monitoring, desktop-pet layout |
| Migration layer | first-run copy of legacy files | deletion, move, overwrite |
| Packaging | bundle layout, icon, architecture merge, signing | runtime state |

Every coordinator exposes idempotent `start` and `stop` behavior. Shutdown invalidates timers, event monitors, event taps, panels, and sleep assertions.

## State Layout

Use a unique root per product:

```text
~/Library/Application Support/<CompanionProduct>/
├── EfficiencyIsland/
│   ├── settings.json
│   └── daily-records.json
└── Tracker/
    └── tracker-state.json
```

Keep the following separate:

- Character position and scale: small display preferences, persisted after completed interaction.
- Work/break and input totals: daily records.
- Reminder configuration: settings.
- Tracker tasks and pipeline: tracker state.
- Bundled seed data: immutable JSON in the app bundle.

Decode new fields with defaults so older state remains readable.

## Desktop Pet Geometry

The visible character and metrics pill are separate layout regions.

- Character: Q art only; aspect-fit, horizontally centered, bottom-aligned, and independently scalable.
- Metrics pill: fixed dimensions and typography; never inherits character scale.
- Dragging moves the complete pet window and persists its screen origin.
- Edge dragging adjusts only character scale and preserves character center and bottom edge.
- Clicking the character toggles the control panel; outside clicks hide that panel.
- Appearance-specific text color may change, but the pill background remains stable when required by the profile.

State images must share a semantic visible-height target even when their source canvases differ. Use the bundled generic frame/footer geometry as the default contract. At 100% scale, the visible alpha bottom should sit roughly 0–6 points above the metrics pill. AppKit image views must use bottom alignment so a wide aspect-fit image does not float in the vertical center of its frame.

Desktop-pet state rendering uses the Q/small mapping (`assetName`). Control-panel rendering uses the independent full-proportion portrait mapping (`panelAssetName`) and state-specific placement. These routes are not interchangeable.

## Tracker Modes

The general tracker provides calendar, Daily Top 3, deadlines, status, next action, and notes. Domain variants add a typed pipeline rather than hard-coding unrelated fields into the general tracker.

Examples:

- PhD: institution, route, supervisor, contact, stage, deadline, follow-up.
- Job search: company, role, contact, interview stage, deadline, next action.
- Study: course, module, assessment, status, deadline, next action.

## Permissions

- EventKit: request read access and expose clear denied/unavailable states.
- Input Monitoring/Accessibility: required only for input metrics; the app must remain usable without them.
- No-sleep: opt-in and always released at shutdown.
- Launch at login: implement only when real login-item support exists; do not present a placeholder as working functionality.

## Packaging

Build arm64 and x86_64 separately, merge only the executable, copy architecture-independent resources, generate the icon without distortion, clear extended attributes, sign the completed bundle, then create the zip. Never mutate the bundle after signing.
