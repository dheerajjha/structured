# Tickd – Get Tasks Done

**Subtitle**: Simple to do list & daily planner

A SwiftUI daily planner (iOS 26.2+ / watchOS 26.2+).
**Stack**: SwiftUI, SwiftData, Mixpanel analytics, Azure OpenAI proxy for AI chat, BugReporterSDK.

---

## Project Layout

```
structured/
├── structured/                     ← iOS app target
│   ├── structuredApp.swift         ← @main, ModelContainer, BugReporter & Analytics init
│   ├── ContentView.swift           ← Root view: tab bar, header, week strip, piano/sheet gesture, FAB
│   ├── Models/
│   │   ├── StructuredTask.swift    ← Core SwiftData @Model (title, time, duration, color, icon, subtasks, anchors)
│   │   └── Subtask.swift           ← SwiftData @Model linked to StructuredTask via @Relationship
│   ├── ViewModels/
│   │   ├── TimelineViewModel.swift ← Date navigation, layout math (hourHeight, yPosition), task editor state
│   │   └── AIViewModel.swift       ← AI chat state, send/parse/action pipeline, prompt construction
│   ├── Views/
│   │   ├── Timeline/
│   │   │   ├── TimelineView.swift          ← DayTimelineView — task list with gaps, current-time badge, swipe/context actions
│   │   │   ├── TaskBlockView.swift         ← Single task row (icon, title, time, completion circle)
│   │   │   ├── AllDayTasksView.swift       ← Horizontal chip strip for all-day tasks
│   │   │   ├── CurrentTimeIndicatorView.swift ← Red dot + line (ZStack overlay, unused in current list layout)
│   │   │   ├── HourGridView.swift          ← 24-hour label + divider grid (ZStack overlay, unused in current list layout)
│   │   │   └── PianoWeekView.swift         ← Mini week overview with colored capsules per day
│   │   ├── Task/
│   │   │   ├── TaskEditorView.swift        ← Create/edit sheet: title, icon, color, time, duration, notes, subtasks
│   │   │   ├── ColorPickerView.swift       ← 6×2 preset color grid
│   │   │   └── IconPickerView.swift        ← 6-column SF Symbol picker (65+ icons)
│   │   ├── Inbox/
│   │   │   └── InboxView.swift             ← "Later" tab: unscheduled task list + InboxRowView
│   │   ├── AI/
│   │   │   └── AIView.swift                ← AI chat tab: messages, suggestions, speech input, action execution, help sheet
│   │   ├── Onboarding/
│   │   │   ├── OnboardingContainerView.swift   ← 7-page TabView flow + saveAndFinish() persists anchors & first task
│   │   │   ├── OnboardingWelcomePage.swift     ← Page 1: coral splash
│   │   │   ├── OnboardingBenefitsPage.swift    ← Page 2: benefit rows
│   │   │   ├── OnboardingTimePickerPage.swift  ← Pages 3-4: reusable scroll wheel (wake/bed), also used by SettingsView
│   │   │   ├── OnboardingTaskEntryPage.swift   ← Page 5: task name + suggestion chips
│   │   │   ├── OnboardingTaskStylePage.swift   ← Page 6: duration pills + color circles
│   │   │   └── OnboardingSummaryPage.swift     ← Page 7: preview timeline + "Finish Setup"
│   │   ├── Settings/
│   │   │   └── SettingsView.swift          ← Anchor time editing, CSV/iCal export, about section
│   │   └── Shared/
│   │       └── TaskIconView.swift          ← TaskIconView + CompletionCircleView (used everywhere)
│   ├── Services/
│   │   ├── AIService.swift             ← HTTP client to Azure OpenAI proxy, ChatMessage model
│   │   ├── AnalyticsService.swift      ← Mixpanel wrapper + all event name constants
│   │   ├── DailyAnchorManager.swift    ← Rise & Shine / Wind Down anchor creation, global time propagation
│   │   └── SpeechRecognizer.swift      ← SFSpeechRecognizer + AVAudioEngine for voice input
│   ├── Utilities/
│   │   ├── ColorExtensions.swift       ← Color(hex:), TaskColor presets, .pastel() helper
│   │   └── DateHelpers.swift           ← Date extensions (startOfDay, weekDays, atTime, etc.) + TimeFormatting
│   └── Assets.xcassets/
│       └── OnboardingWelcome, OnboardingBenefits images, AccentColor, AppIcon
├── structured Watch App/               ← watchOS target (placeholder — not yet implemented)
│   ├── structuredApp.swift
│   └── ContentView.swift
├── Images/                             ← Reference screenshots (1.png, 2.png, 3.png)
└── structured.xcodeproj/
```

---

## Architecture

- **State management**: `@Observable` (Swift 5.9) + SwiftData for persistence.
- **Data container**: `ModelContainer` with `StructuredTask` and `Subtask` schemas, configured in `structuredApp.swift`. iCloud/App Group commented out (TODO).
- **Navigation**: Custom 4-tab bottom bar in `ContentView.swift` — `Later` (inbox), `Today` (timeline), `AI`, `Settings`.
- **Onboarding**: Gated by `@AppStorage("hasCompletedOnboarding")` in `ContentView`.

---

## Feature → File Map

### Task CRUD
| What to change | File(s) |
|---|---|
| Task data shape (add/remove fields) | `Models/StructuredTask.swift` |
| Subtask data shape | `Models/Subtask.swift` |
| Create / edit / delete task UI | `Views/Task/TaskEditorView.swift` |
| Color palette | `Views/Task/ColorPickerView.swift` + `Utilities/ColorExtensions.swift` (TaskColors.all) |
| Icon library | `Views/Task/IconPickerView.swift` |
| Shared icon + completion circle | `Views/Shared/TaskIconView.swift` |

### Timeline (Today tab)
| What to change | File(s) |
|---|---|
| Day view layout (task list, gaps, current-time) | `Views/Timeline/TimelineView.swift` (DayTimelineView) |
| Task row appearance | `Views/Timeline/TaskBlockView.swift` |
| All-day chips | `Views/Timeline/AllDayTasksView.swift` |
| Hour grid overlay (currently unused) | `Views/Timeline/HourGridView.swift` |
| Current-time red line overlay (currently unused) | `Views/Timeline/CurrentTimeIndicatorView.swift` |
| Piano week overview (drag-down) | `Views/Timeline/PianoWeekView.swift` |
| Date navigation, layout math, scroll helpers | `ViewModels/TimelineViewModel.swift` |
| Header (date, chevrons, Today button) | `ContentView.swift` → `headerView` |
| Week strip (Mon–Sun dots) | `ContentView.swift` → `weekStripView` |
| Piano drag gesture | `ContentView.swift` → `tabContent` (.gesture) |

### Inbox (Later tab)
| What to change | File(s) |
|---|---|
| Unscheduled task list + empty state | `Views/Inbox/InboxView.swift` |
| Inbox row appearance | `Views/Inbox/InboxView.swift` → `InboxRowView` |

### AI Chat
| What to change | File(s) |
|---|---|
| Chat UI, suggestions, speech, action execution | `Views/AI/AIView.swift` |
| AI state, prompt, response parsing, action types | `ViewModels/AIViewModel.swift` |
| HTTP client to OpenAI proxy | `Services/AIService.swift` |
| Speech-to-text engine | `Services/SpeechRecognizer.swift` |

### Onboarding
| What to change | File(s) |
|---|---|
| Flow container + page ordering + save logic | `Views/Onboarding/OnboardingContainerView.swift` |
| Welcome splash | `Views/Onboarding/OnboardingWelcomePage.swift` |
| Benefits page | `Views/Onboarding/OnboardingBenefitsPage.swift` |
| Wake-up / bedtime scroll picker (reusable) | `Views/Onboarding/OnboardingTimePickerPage.swift` |
| Task name entry + suggestions | `Views/Onboarding/OnboardingTaskEntryPage.swift` |
| Duration + color picker | `Views/Onboarding/OnboardingTaskStylePage.swift` |
| Summary preview + finish | `Views/Onboarding/OnboardingSummaryPage.swift` |

### Settings
| What to change | File(s) |
|---|---|
| Anchor time editing (wake/bed) | `Views/Settings/SettingsView.swift` |
| CSV / iCal export | `Views/Settings/SettingsView.swift` |
| ShareSheet (UIKit bridge) | `Views/Settings/SettingsView.swift` (bottom) |

### Daily Anchors (Rise and Shine / Wind Down)
| What to change | File(s) |
|---|---|
| Anchor creation per day, global time propagation | `Services/DailyAnchorManager.swift` |
| Anchor constants & UserDefaults keys | `Services/DailyAnchorManager.swift` (AnchorType, AnchorDefaults) |
| Protected task filtering | `StructuredTask.isProtected`, `StructuredTask.anchorType` |

### Analytics
| What to change | File(s) |
|---|---|
| Mixpanel setup, event tracking | `Services/AnalyticsService.swift` |
| Event name constants | `Services/AnalyticsService.swift` → `Analytics.Event` |

### App Entry & Tab Bar
| What to change | File(s) |
|---|---|
| App lifecycle, ModelContainer, BugReporter init | `structuredApp.swift` |
| Tab bar layout, FAB button | `ContentView.swift` → `bottomBar` |
| Tab enum (add/remove tabs) | `ContentView.swift` → `AppTab` |

---

## Key Concepts

### Anchor Tasks
`Rise and Shine` and `Wind Down` are special **protected** tasks (`isProtected = true`, `anchorType = "wake_up" | "wind_down"`). They are auto-created for each viewed day by `DailyAnchorManager.ensureAnchors()`. Users can override their time per-day (`isUserModifiedTime`); global changes from Settings propagate only to unmodified days.

### AI Actions
The AI returns `[ACTIONS]{...}[/ACTIONS]` blocks parsed by `AIViewModel.parseResponse()`. Supported: `move_task`, `create_task`, `create_unscheduled_task`, `complete_task`. Protected tasks are excluded from actions.

### Timeline Layout
Current layout uses a **flat List** (not a ZStack grid). Tasks are sorted by `startTime` with gap rows inserted between them. `HourGridView` and `CurrentTimeIndicatorView` exist but are unused in the current list-based design.

### Onboarding Flow
7 pages in a `TabView(.page)`. On finish, `saveAndFinish()` creates anchor tasks + optional user task, persists wake/bed times to UserDefaults.

---

## Watch App Status
**Not yet implemented.** The `structured Watch App/` target contains only boilerplate `ContentView` and `structuredApp`. No models, no WatchConnectivity, no complications.

---

## Conventions
- **Accent color**: Coral `#E8907E` (primary), Slate Blue `#7C97AB` (wind down).
- **Analytics**: Every user-facing action is tracked via `Analytics.track()`. Add new events to `Analytics.Event`.
- **SwiftData**: All persistence through `@Query` and `ModelContext`. No Core Data.
- **No storyboards / UIKit views** except `ShareSheet` (UIActivityViewController bridge in SettingsView).

---

## Not Yet Built (from original plan)
- Recurring tasks / Recurrence model
- Focus mode / Live Activities
- Notifications (UNUserNotificationCenter)
- Widgets (WidgetKit — iOS & Watch)
- Calendar / Reminders import (EventKit)
- Apple Shortcuts (AppIntents)
- Replan triage view
- Energy Monitor / Cycle Seasons
- Pro paywall (StoreKit 2)
- iCloud sync / App Group container
- Drag-and-drop rescheduling on timeline
- Watch app implementation
