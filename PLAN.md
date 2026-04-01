# Structured App — Implementation Plan

## Project Snapshot
- **Starter state**: Two blank SwiftUI targets (iOS 26.2+, watchOS 26.2+), no models/views/logic yet
- **Goal**: Feature parity with the Structured daily planner app (App Store)
- **Stack**: SwiftUI, Swift Data (or Core Data), iCloud sync, WidgetKit, WatchConnectivity

---

## Architecture

```
structured/
├── App/
│   ├── structuredApp.swift          # @main, app lifecycle
│   └── AppState.swift               # Global observable state
├── Models/
│   ├── Task.swift                   # Core task model (SwiftData @Model)
│   ├── Recurrence.swift             # Recurrence rule model
│   ├── EnergyEntry.swift            # Energy monitor model
│   └── CycleSeason.swift            # Cycle seasons model
├── ViewModels/
│   ├── TimelineViewModel.swift      # Daily timeline logic
│   ├── InboxViewModel.swift         # Inbox management
│   ├── WeeklyViewModel.swift        # Weekly view logic
│   └── ReminderImportViewModel.swift
├── Views/
│   ├── Timeline/
│   │   ├── TimelineView.swift       # Main scrollable day view
│   │   ├── TaskBlockView.swift      # Individual task block on timeline
│   │   ├── AllDayTasksView.swift    # All-day task strip
│   │   ├── CurrentTimeIndicator.swift
│   │   └── FreeSlotView.swift       # Empty gap visualization
│   ├── Task/
│   │   ├── TaskEditorView.swift     # Create/edit task sheet
│   │   ├── SubtaskRowView.swift
│   │   ├── IconPickerView.swift
│   │   └── ColorPickerView.swift
│   ├── Inbox/
│   │   ├── InboxView.swift
│   │   └── InboxTaskRow.swift
│   ├── Weekly/
│   │   ├── WeeklyView.swift
│   │   └── DayColumnView.swift
│   ├── Focus/
│   │   ├── FocusTimerView.swift     # Full-screen countdown
│   │   └── LiveActivityAttributes.swift
│   ├── Replan/
│   │   └── ReplanView.swift         # Swipe triage for past tasks
│   ├── Settings/
│   │   └── SettingsView.swift
│   └── Shared/
│       ├── TaskIconView.swift
│       └── TimelineHourLabel.swift
├── Widgets/
│   ├── TimelineWidget.swift
│   ├── InboxWidget.swift
│   ├── SingleTaskWidget.swift
│   └── SubtaskWidget.swift
├── Watch/                           # watchOS target
│   ├── WatchTimelineView.swift
│   ├── WatchTaskRow.swift
│   └── WatchComplication.swift
├── Sync/
│   ├── iCloudSyncManager.swift
│   └── WatchConnectivityManager.swift
└── Utilities/
    ├── DateHelpers.swift
    ├── ColorExtensions.swift
    └── NotificationManager.swift
```

**State management**: `@Observable` (Swift 5.9 Observation framework) + SwiftData for persistence
**Sync**: CloudKit-backed SwiftData container (free iCloud sync with zero extra code)
**Watch**: WatchConnectivity for real-time updates when both devices are reachable

---

## Data Model

### Task (SwiftData `@Model`)
```swift
@Model class Task {
    var id: UUID
    var title: String
    var startTime: Date?          // nil = all-day
    var duration: TimeInterval    // in seconds
    var date: Date                // calendar day
    var notes: String
    var colorHex: String
    var iconName: String          // SF Symbol or custom
    var isCompleted: Bool
    var isAllDay: Bool
    var isInbox: Bool             // no date assigned
    var subtasks: [Subtask]
    var recurrence: Recurrence?
    var order: Int                // for same-time ordering
    var createdAt: Date
}

@Model class Subtask {
    var id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
    var task: Task?
}

@Model class Recurrence {
    var frequency: RecurrenceFrequency  // .daily / .weekly / .monthly
    var interval: Int
    var endDate: Date?
    var daysOfWeek: [Int]         // for weekly
}

@Model class EnergyEntry {
    var date: Date
    var level: Int                // 1–5
}
```

---

## Feature Phases

### Phase 1 — Core Timeline (MVP)
**Goal**: Functional daily timeline with task creation, editing, and completion.

| Feature | Files |
|---|---|
| Scrollable vertical timeline (hour grid) | `TimelineView`, `TimelineHourLabel` |
| Task blocks (color, icon, title, time) | `TaskBlockView` |
| Current time indicator (red line) | `CurrentTimeIndicator` |
| All-day task strip at top | `AllDayTasksView` |
| Create/edit task sheet (title, time, duration, color, icon, notes) | `TaskEditorView` |
| Mark task complete (tap checkmark) | `TimelineViewModel` |
| SwiftData persistence | `Task.swift`, app container |
| Day navigation (prev/next arrows + date picker) | `TimelineView` |
| Undo/redo | `ModelContext` undo manager |

**Key implementation notes**:
- Timeline is a `ScrollView` + `ZStack` overlay: hour labels on left, task blocks positioned by `(startMinute / 1440) * totalHeight`
- Task block height = `(duration / 86400) * totalHeight`
- `ScrollViewReader` to auto-scroll to current hour on launch
- `GeometryReader` for drag-to-reschedule coordinates

---

### Phase 2 — Inbox & Drag-to-Schedule
**Goal**: Capture tasks without a time; drag them onto the timeline.

| Feature | Files |
|---|---|
| Inbox tab (unscheduled tasks list) | `InboxView`, `InboxTaskRow` |
| Quick-add from inbox | `InboxViewModel` |
| Drag task from inbox → timeline drop zone | `InboxView` + `TimelineView` drop delegates |
| Drag task block within timeline to reschedule | `TaskBlockView` drag gesture |
| Visual drop target highlight on timeline | `TimelineView` |
| Duplicate day / copy tasks | `TimelineViewModel.duplicateDay()` |

---

### Phase 3 — Weekly & Navigation Views
**Goal**: Weekly timeline view mirroring daily design.

| Feature | Files |
|---|---|
| Horizontal scroll of 7 day columns | `WeeklyView`, `DayColumnView` |
| Mini task blocks per day column | `DayColumnView` |
| Tap column → navigate to that day's timeline | `WeeklyView → TimelineView` |
| Month picker / date jumping | shared date picker component |

---

### Phase 4 — Recurring Tasks
**Goal**: Daily/weekly/monthly repeating tasks.

| Feature | Files |
|---|---|
| Recurrence picker in task editor | `TaskEditorView` recurrence section |
| `Recurrence` model | `Recurrence.swift` |
| Virtual instance generation on query | `TimelineViewModel` recurrence expansion |
| Edit single vs. all occurrences | `TaskEditorView` confirmation sheet |

**Implementation**: Store one `Task` with recurrence rule; generate virtual `TaskOccurrence` values on the fly when fetching for a day (no explosion of rows in DB).

---

### Phase 5 — Focus Mode & Live Activities
**Goal**: Full-screen countdown timer for active task.

| Feature | Files |
|---|---|
| Focus Mode view (full-screen countdown) | `FocusTimerView` |
| Tap "Focus Now" on task block | `TaskBlockView` button |
| Live Activity (Lock Screen + Dynamic Island) | `LiveActivityAttributes.swift`, ActivityKit |
| Live Activity starts/ends with Focus Mode | `FocusTimerView` |
| Edit end time while in focus | `FocusTimerView` |
| Mark complete from focus screen | `FocusTimerView` |

**Implementation**: `ActivityKit` `Activity<LiveActivityAttributes>`. Show elapsed/remaining progress ring in Dynamic Island compact view.

---

### Phase 6 — Notifications
**Goal**: Timely alerts for upcoming tasks.

| Feature | Files |
|---|---|
| Schedule `UNUserNotificationCenter` alerts per task | `NotificationManager` |
| Default: notify at task start time | `NotificationManager` |
| Custom lead time per task (Pro placeholder) | `TaskEditorView` |
| Reschedule notifications on task edit/delete | `NotificationManager` |
| Notification tap → deep link to task | app URL scheme handler |

---

### Phase 7 — Apple Watch App
**Goal**: View timeline and complete tasks from wrist.

| Feature | Files |
|---|---|
| Watch timeline list (current + upcoming tasks) | `WatchTimelineView` |
| Task row with icon, title, time | `WatchTaskRow` |
| Mark complete from Watch | `WatchTaskRow` toggle |
| WatchConnectivity sync manager | `WatchConnectivityManager` |
| Watch Complications (3 sizes) | `WatchComplication` (WidgetKit on watchOS) |
| Interactive complication (mark complete from face) | `WatchComplication` button |
| Timeline entry provider for complications | `WatchComplication` `TimelineProvider` |

**Implementation**:
- Use `WKExtendedRuntimeSession` for background updates
- Complication uses WidgetKit on watchOS 9+ (`Widget` conformance)
- `WatchConnectivity` sends `applicationContext` for passive sync; `sendMessage` for interactive complete

---

### Phase 8 — Widgets (iOS Home Screen & Lock Screen)
**Goal**: Glanceable timeline and task widgets.

| Feature | Files |
|---|---|
| Timeline widget (S/M/L) | `TimelineWidget` |
| Inbox widget (S/M/L) | `InboxWidget` |
| Single task widget | `SingleTaskWidget` |
| Subtask widget | `SubtaskWidget` |
| Lock screen widgets (2 styles) | inside respective widget files |
| StandBy mode optimization | `.widgetAccentable()`, `.widgetBackground()` |
| Interactive completion from widget | `AppIntent` + Button in widget |
| "Add task" button on widget | `AppIntent` |

**Implementation**: All widgets share a `WidgetDataProvider` that reads from the SwiftData store via a shared App Group container.

---

### Phase 9 — Calendar & Reminders Integration
**Goal**: Import external calendars and Apple Reminders (Pro features).

| Feature | Files |
|---|---|
| `EventKit` calendar access | `CalendarImportManager` |
| Display imported events as read-only blocks | `TaskBlockView` (isImported flag) |
| `EventKit` Reminders list import | `ReminderImportViewModel` |
| Imported reminders land in Inbox | `InboxViewModel` |
| Timezone per-task support | `Task` model `timeZoneID` field |

---

### Phase 10 — Apple Shortcuts Integration
**Goal**: Siri/Shortcuts actions for power users.

| Feature | Files |
|---|---|
| `AppIntents` framework | `StructuredAppShortcuts.swift` |
| Open today's timeline intent | `OpenTodayIntent` |
| Create task intent (all properties) | `CreateTaskIntent` |
| Complete task intent | `CompleteTaskIntent` |
| Query tasks for date intent | `QueryTasksIntent` |
| Donate shortcuts phrases | `AppShortcutsProvider` |

---

### Phase 11 — Replan
**Goal**: Triage overdue/incomplete past tasks.

| Feature | Files |
|---|---|
| Replan entry point (badge on past days) | `TimelineView` past-day indicator |
| Swipe card triage UI | `ReplanView` |
| Actions: reschedule / complete / inbox / delete | `ReplanView` swipe gestures |
| Batch replan across multiple days | `ReplanViewModel` |

**Implementation**: Fetch all tasks where `date < today && !isCompleted && !isInbox`. Present as a card stack with swipe left/right gestures mapped to actions.

---

### Phase 12 — Energy Monitor & Cycle Seasons
**Goal**: Wellness overlays on the timeline.

| Feature | Files |
|---|---|
| Daily energy level logger (1–5 scale) | `EnergyEntry` model, `EnergyLogView` |
| Energy bar overlay on timeline | `TimelineView` energy overlay layer |
| Energy in widgets | `TimelineWidget` all-day section |
| Cycle phase input & tracking | `CycleSeason` model, settings |
| Cycle phase overlay on timeline | `TimelineView` |
| Cycle Seasons in widgets | `TimelineWidget` |

---

### Phase 13 — Settings, Appearance & Accessibility
**Goal**: Polish and personalization.

| Feature | Files |
|---|---|
| Light/Dark/System appearance | `SettingsView`, `@AppStorage` |
| Alternate app icons | `SettingsView` `UIApplication.setAlternateIconName` |
| Dyslexia-friendly font toggle | `SettingsView`, custom `Font` extension |
| VoiceOver labels on all task blocks | `TaskBlockView` `.accessibilityLabel` |
| Dynamic Type support | all views use `.font(.body)` etc. |
| Custom color palette (Pro) | `ColorPickerView` |
| Premium icon library (Pro) | `IconPickerView` |
| Pro paywall / subscription (StoreKit 2) | `ProPaywallView`, `StoreManager` |
| Scholarship / restore purchase | `StoreManager` |

---

## Shared App Group (iOS ↔ Widgets ↔ Watch)

All targets share `group.heywrist.structured` App Group so the SwiftData store is accessible from:
- Main iOS app
- Widget extension
- Watch extension (via WatchConnectivity mirror)

---

## iCloud Sync

```swift
let container = ModelContainer(
    for: Task.self, Subtask.self, Recurrence.self, EnergyEntry.self,
    configurations: ModelConfiguration(cloudKitDatabase: .automatic)
)
```

SwiftData + CloudKit handles cross-device sync automatically. No extra sync code needed for basic iCloud.

---

## Build Order (Recommended Sprints)

| Sprint | Phase | Deliverable |
|---|---|---|
| 1 | Phase 1 | Working timeline, tasks persist, day nav |
| 2 | Phase 2 | Inbox + drag-to-schedule |
| 3 | Phase 3 | Weekly view |
| 4 | Phase 4 | Recurring tasks |
| 5 | Phase 5 | Focus Mode + Live Activities |
| 6 | Phase 6 | Notifications |
| 7 | Phase 7 | Apple Watch app + complications |
| 8 | Phase 8 | Home screen & lock screen widgets |
| 9 | Phase 9 | Calendar + Reminders import |
| 10 | Phase 10 | Shortcuts / App Intents |
| 11 | Phase 11 | Replan |
| 12 | Phase 12 | Energy Monitor + Cycle Seasons |
| 13 | Phase 13 | Settings, appearance, Pro paywall |

---

## Feature Parity Checklist

### Free Features
- [ ] Visual daily timeline (scrollable, hour grid)
- [ ] Task blocks (color, icon, title, time, duration)
- [ ] Current time indicator
- [ ] All-day tasks strip
- [ ] Task creation / editing (full properties)
- [ ] Subtasks (create, check off, visible in timeline)
- [ ] Notes on tasks (with URL support)
- [ ] Mark task complete
- [ ] Drag & drop rescheduling on timeline
- [ ] Inbox (unscheduled task capture)
- [ ] Drag from inbox to timeline
- [ ] Undo / redo
- [ ] Duplicate day / copy tasks
- [ ] Day navigation
- [ ] Weekly view
- [ ] Monthly view (calendar picker)
- [ ] iCloud sync (cross-device)
- [ ] Basic notifications (at task start)
- [ ] Focus Mode (full-screen countdown)
- [ ] Live Activities (Lock Screen + Dynamic Island)
- [ ] All home screen widgets (Timeline, Inbox, Single, Subtask — S/M/L)
- [ ] Lock screen widgets (2 styles)
- [ ] StandBy mode widgets
- [ ] Energy Monitor
- [ ] Cycle Seasons
- [ ] 30+ language localization (via String Catalogs)
- [ ] VoiceOver / Voice Control / Dynamic Type
- [ ] Dyslexia-friendly font
- [ ] Alternate app icons
- [ ] Control Center integration (iOS 18+)
- [ ] Apple Watch app (view + complete)
- [ ] Watch complications (3 sizes, interactive)

### Pro Features
- [ ] Recurring tasks (daily / weekly / monthly)
- [ ] Calendar integration (EventKit import)
- [ ] Apple Reminders import
- [ ] Replan (swipe triage for past tasks)
- [ ] Structured AI (natural language scheduling, image-to-tasks)
- [ ] Customizable notifications (lead time, style per task)
- [ ] Custom color palette
- [ ] Premium icons
- [ ] StoreKit 2 subscription (monthly / annual / lifetime)
- [ ] Family Sharing
- [ ] Scholarship (restore + apply flow)

### Platform-Specific
- [ ] Apple Shortcuts / App Intents (iOS)
- [ ] CarPlay (iOS 26+)
- [ ] Mac Catalyst or native macOS (future)
