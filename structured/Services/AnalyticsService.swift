import Foundation
import Mixpanel

// MARK: - Analytics Service

enum Analytics {

    // MARK: - Session

    static let sessionId = UUID().uuidString

    // MARK: - Setup

    static func setup() {
        Mixpanel.initialize(token: "f8aebee34dee964043f41b1bae1316d5", trackAutomaticEvents: false)
        Mixpanel.mainInstance().registerSuperProperties(["session_id": sessionId])
    }

    // MARK: - Track

    static func track(_ event: String, properties: [String: MixpanelType]? = nil) {
        Mixpanel.mainInstance().track(event: event, properties: properties)
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
