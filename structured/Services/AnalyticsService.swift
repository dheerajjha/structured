import Foundation
import Mixpanel
import UIKit

enum Analytics {

    static let sessionId = UUID().uuidString

    private static let projectToken = "f8aebee34dee964043f41b1bae1316d5"

    /// Pinned Mixpanel instance — BugReporterSDK reroutes `mainInstance()`
    /// via `setMainInstance(name:)`, so we must hold our own reference.
    private static var instance: MixpanelInstance?
    private static let distinctIdKey = "Analytics.structured.stableDistinctId"
    private static var flushHooksRegistered = false

    static func setup() {
        if instance != nil { return }
        let mp = Mixpanel.initialize(token: projectToken, trackAutomaticEvents: false, instanceName: "structured")
        #if DEBUG
        mp.loggingEnabled = true
        #endif
        instance = mp
        mp.registerSuperProperties(["session_id": sessionId])
        identifyStableUser()
        registerFlushHooks()
    }

    private static var stableDistinctId: String {
        if let cached = UserDefaults.standard.string(forKey: distinctIdKey) { return cached }
        let fresh = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(fresh, forKey: distinctIdKey)
        return fresh
    }

    private static func identifyStableUser() {
        guard let mp = instance else { return }
        mp.identify(distinctId: stableDistinctId)
        let now = Date()
        mp.people.setOnce(properties: ["$first_seen": now])
        mp.people.set(properties: [
            "$last_seen": now,
            "app_version": Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
            "build_number": Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
        ])
    }

    private static func registerFlushHooks() {
        guard !flushHooksRegistered else { return }
        flushHooksRegistered = true
        let nc = NotificationCenter.default
        nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { _ in instance?.flush() }
        nc.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { _ in instance?.flush() }
    }

    static func flush() { instance?.flush() }

    static func track(_ event: String, properties: [String: MixpanelType]? = nil) {
        instance?.track(event: event, properties: properties)
    }

    // MARK: - Event Names

    enum Event {
        // App lifecycle
        static let appOpened                = "app_opened"

        // Onboarding
        static let onboardingStarted        = "onboarding_started"
        static let onboardingPageViewed      = "onboarding_page_viewed"
        static let onboardingCompleted       = "onboarding_completed"
        static let onboardingWakeTimeSet     = "onboarding_wake_time_set"
        static let onboardingBedTimeSet      = "onboarding_bed_time_set"
        static let onboardingTaskEntered     = "onboarding_task_entered"
        static let onboardingTaskStyleSet    = "onboarding_task_style_set"

        // Tab navigation
        static let tabSwitched               = "tab_switched"

        // Task CRUD
        static let taskCreated               = "task_created"
        static let taskUpdated               = "task_updated"
        static let taskDeleted               = "task_deleted"
        static let taskCompleted             = "task_completed"
        static let taskUncompleted           = "task_uncompleted"
        static let taskUnscheduled           = "task_unscheduled"

        // Task editor
        static let taskEditorOpened          = "task_editor_opened"
        static let iconPickerOpened          = "icon_picker_opened"
        static let durationSelected          = "duration_selected"
        static let colorSelected             = "color_selected"
        static let subtaskAdded              = "subtask_added"
        static let subtaskRemoved            = "subtask_removed"

        // Timeline
        static let dateNavigated             = "date_navigated"
        static let datePickerOpened          = "date_picker_opened"
        static let pianoViewToggled          = "piano_view_toggled"
        static let gapAddTaskTapped          = "gap_add_task_tapped"
        static let todayButtonTapped         = "today_button_tapped"

        // Inbox
        static let inboxViewed               = "inbox_viewed"
        static let inboxTaskScheduleTapped   = "inbox_task_schedule_tapped"

        // AI
        static let aiMessageSent             = "ai_message_sent"
        static let aiSuggestionTapped        = "ai_suggestion_tapped"
        static let aiConversationCleared     = "ai_conversation_cleared"
        static let aiActionExecuted          = "ai_action_executed"
        static let aiSpeechStarted           = "ai_speech_started"
        static let aiSpeechStopped           = "ai_speech_stopped"
        static let aiError                   = "ai_error"

        // Settings
        static let settingsViewed            = "settings_viewed"
        static let wakeTimeChanged           = "wake_time_changed"
        static let bedTimeChanged            = "bed_time_changed"

        // FAB
        static let fabTapped                 = "fab_tapped"
    }
}
