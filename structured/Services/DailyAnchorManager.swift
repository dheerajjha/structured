import Foundation
import SwiftData

// MARK: - Anchor Type Constants

enum AnchorType {
    static let wakeUp   = "wake_up"
    static let windDown = "wind_down"
}

// MARK: - Shared AppStorage keys (used here, in ContentView, and in SettingsView)

enum AnchorDefaults {
    static let wakeHour   = "anchor_wake_hour"
    static let wakeMinute = "anchor_wake_minute"
    static let bedHour    = "anchor_bed_hour"
    static let bedMinute  = "anchor_bed_minute"
}

// MARK: - Daily Anchor Manager

/// Ensures Rise and Shine / Wind Down tasks exist for any viewed day,
/// and propagates global time changes without stomping user-overridden days.
struct DailyAnchorManager {

    // MARK: - Read stored defaults

    static var storedWakeHour:   Int { UserDefaults.standard.object(forKey: AnchorDefaults.wakeHour)   != nil ? UserDefaults.standard.integer(forKey: AnchorDefaults.wakeHour)   : 7 }
    static var storedWakeMinute: Int { UserDefaults.standard.object(forKey: AnchorDefaults.wakeMinute) != nil ? UserDefaults.standard.integer(forKey: AnchorDefaults.wakeMinute) : 0 }
    static var storedBedHour:    Int { UserDefaults.standard.object(forKey: AnchorDefaults.bedHour)    != nil ? UserDefaults.standard.integer(forKey: AnchorDefaults.bedHour)    : 23 }
    static var storedBedMinute:  Int { UserDefaults.standard.object(forKey: AnchorDefaults.bedMinute)  != nil ? UserDefaults.standard.integer(forKey: AnchorDefaults.bedMinute)  : 0 }

    // MARK: - Convenience: persist from a Date (used by onboarding)

    static func saveWakeTime(_ date: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set(c.hour   ?? 7, forKey: AnchorDefaults.wakeHour)
        UserDefaults.standard.set(c.minute ?? 0, forKey: AnchorDefaults.wakeMinute)
    }

    static func saveBedTime(_ date: Date) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        UserDefaults.standard.set(c.hour   ?? 23, forKey: AnchorDefaults.bedHour)
        UserDefaults.standard.set(c.minute ?? 0,  forKey: AnchorDefaults.bedMinute)
    }

    // MARK: - Ensure anchors exist for a date

    static func ensureAnchors(
        for date: Date,
        context: ModelContext,
        wakeHour: Int, wakeMinute: Int,
        bedHour: Int, bedMinute: Int
    ) {
        let day = date.startOfDay
        let cal = Calendar.current

        guard let existing = try? context.fetch(
            FetchDescriptor<StructuredTask>(predicate: #Predicate { $0.isProtected && $0.date == day })
        ) else { return }

        let hasWake = existing.contains { $0.anchorType == AnchorType.wakeUp }
        let hasWind = existing.contains { $0.anchorType == AnchorType.windDown }

        if !hasWake {
            let t = StructuredTask(
                title: "Rise and Shine",
                startTime: cal.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: day),
                duration: 0, date: day,
                colorHex: "#E8907E", iconName: "sun.max.fill",
                isCompleted: false, order: 0,
                anchorType: AnchorType.wakeUp, isProtected: true
            )
            context.insert(t)
        }

        if !hasWind {
            let t = StructuredTask(
                title: "Wind Down",
                startTime: cal.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: day),
                duration: 0, date: day,
                colorHex: "#7C97AB", iconName: "moon.fill",
                isCompleted: false, order: 999,
                anchorType: AnchorType.windDown, isProtected: true
            )
            context.insert(t)
        }
    }

    // MARK: - Propagate global time change (Settings)

    /// Updates future unmodified anchor tasks when the user changes times in Settings.
    static func updateGlobalTimes(
        context: ModelContext,
        wakeHour: Int, wakeMinute: Int,
        bedHour: Int, bedMinute: Int
    ) {
        let today = Date().startOfDay
        let cal   = Calendar.current

        guard let anchors = try? context.fetch(
            FetchDescriptor<StructuredTask>(predicate: #Predicate {
                $0.isProtected && !$0.isUserModifiedTime && $0.date >= today
            })
        ) else { return }

        for task in anchors {
            switch task.anchorType {
            case AnchorType.wakeUp:
                task.startTime = cal.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: task.date)
            case AnchorType.windDown:
                task.startTime = cal.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: task.date)
            default: break
            }
        }
    }
}
