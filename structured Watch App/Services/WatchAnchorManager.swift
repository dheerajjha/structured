import Foundation
import SwiftData

/// Anchor-type tags matching the iPhone's `AnchorType` constants.
enum WatchAnchorType {
    static let wakeUp   = "wake_up"
    static let windDown = "wind_down"
}

/// UserDefaults keys used by the watch for anchor preferences. These mirror
/// the iPhone's `AnchorDefaults` keys so the `@AppStorage` bindings used by
/// `WatchSettingsView` stay compatible after a phone sync.
enum WatchAnchorDefaults {
    static let wakeHour   = "anchor_wake_hour"
    static let wakeMinute = "anchor_wake_minute"
    static let bedHour    = "anchor_bed_hour"
    static let bedMinute  = "anchor_bed_minute"
}

/// Creates local `Rise and Shine` / `Wind Down` tasks on the watch when the
/// iPhone hasn't (or can't) push its own anchor tasks yet. Without this, a
/// user who opens the watch app standalone sees an empty timeline.
///
/// Anchors created here are marked `isProtected = true` so the sync pipeline
/// treats them the same as iPhone-owned anchors — they get replaced when the
/// iPhone pushes its authoritative payload.
struct WatchAnchorManager {

    // MARK: - Stored preferences

    static var storedWakeHour:   Int { UserDefaults.standard.object(forKey: WatchAnchorDefaults.wakeHour)   != nil ? UserDefaults.standard.integer(forKey: WatchAnchorDefaults.wakeHour)   : 7 }
    static var storedWakeMinute: Int { UserDefaults.standard.object(forKey: WatchAnchorDefaults.wakeMinute) != nil ? UserDefaults.standard.integer(forKey: WatchAnchorDefaults.wakeMinute) : 0 }
    static var storedBedHour:    Int { UserDefaults.standard.object(forKey: WatchAnchorDefaults.bedHour)    != nil ? UserDefaults.standard.integer(forKey: WatchAnchorDefaults.bedHour)    : 23 }
    static var storedBedMinute:  Int { UserDefaults.standard.object(forKey: WatchAnchorDefaults.bedMinute)  != nil ? UserDefaults.standard.integer(forKey: WatchAnchorDefaults.bedMinute)  : 0 }

    // MARK: - Ensure anchors for a day

    /// Makes sure `Rise and Shine` and `Wind Down` exist for `date` on the watch
    /// store. Safe to call repeatedly — no-op when both anchors are present.
    static func ensureAnchors(for date: Date, context: ModelContext) {
        let day = date.startOfDay
        let cal = Calendar.current

        // Fetch all tasks for this day; we only care about the protected ones.
        let existing = (try? context.fetch(FetchDescriptor<WatchTask>()))?
            .filter { $0.date.isSameDay(as: day) && $0.isProtected } ?? []

        let hasWake = existing.contains { $0.anchorType == WatchAnchorType.wakeUp }
        let hasWind = existing.contains { $0.anchorType == WatchAnchorType.windDown }

        if !hasWake {
            let t = WatchTask(
                title: "Rise and Shine",
                startTime: cal.date(bySettingHour: storedWakeHour, minute: storedWakeMinute, second: 0, of: day),
                duration: 0,
                date: day,
                colorHex: "#E8907E",
                iconName: "sun.max.fill",
                isCompleted: false,
                order: 0,
                anchorType: WatchAnchorType.wakeUp,
                isProtected: true
            )
            context.insert(t)
        }

        if !hasWind {
            let t = WatchTask(
                title: "Wind Down",
                startTime: cal.date(bySettingHour: storedBedHour, minute: storedBedMinute, second: 0, of: day),
                duration: 0,
                date: day,
                colorHex: "#7C97AB",
                iconName: "moon.fill",
                isCompleted: false,
                order: 999,
                anchorType: WatchAnchorType.windDown,
                isProtected: true
            )
            context.insert(t)
        }

        try? context.save()
    }
}
