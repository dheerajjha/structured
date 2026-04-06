import SwiftUI

// MARK: - AI Actions (parsed from model response)

enum AIAction {
    case moveTask(title: String, hour: Int, minute: Int)
    case createTask(title: String, hour: Int, minute: Int, durationMinutes: Int, date: Date?)
    case createUnscheduledTask(title: String, durationMinutes: Int)
    case completeTask(title: String)
}

// MARK: - AI View Model

@Observable
class AIViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var pendingActions: [AIAction] = []

    private var taskContextLines: String = "No tasks today."

    // MARK: - Context

    func updateContext(scheduledTasks: [StructuredTask], unscheduledTasks: [StructuredTask]) {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        var lines: [String] = []

        if !scheduledTasks.isEmpty {
            lines.append("Scheduled tasks (use these exact titles for actions):")
            for t in scheduledTasks {
                let time      = t.startTime.map { fmt.string(from: $0) } ?? "?"
                let dur       = t.durationMinutes > 0 ? " (\(t.durationMinutes) min)" : ""
                let done      = t.isCompleted ? " [completed]" : ""
                let prot      = t.isProtected ? " [protected]" : ""
                lines.append("  • \(time) — \(t.title)\(dur)\(done)\(prot)")
            }
        }

        if !unscheduledTasks.isEmpty {
            lines.append("Unscheduled backlog (Later tab):")
            for t in unscheduledTasks {
                let dur = t.durationMinutes > 0 ? " (\(t.durationMinutes) min)" : ""
                lines.append("  • \(t.title)\(dur)")
            }
        }

        if lines.isEmpty { lines = ["No tasks scheduled today."] }
        taskContextLines = lines.joined(separator: "\n")
    }

    // MARK: - Send

    @MainActor
    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }

        messages.append(ChatMessage(role: "user", content: trimmed))
        inputText = ""
        isLoading = true
        errorMessage = nil

        // YOH-94: Give the AI full temporal context (today + tomorrow dates)
        let now = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "h:mm a"
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd"

        let todayStr    = dateFormatter.string(from: now)
        let nowTimeStr  = timeFormatter.string(from: now)
        let todayISO    = isoFormatter.string(from: now)
        let tomorrowISO = isoFormatter.string(from: calendar.date(byAdding: .day, value: 1, to: now)!)

        let system = """
        You are a friendly AI planning assistant in the Structured daily planner app.
        Today is \(todayStr). Current time is \(nowTimeStr).
        Today's date (ISO): \(todayISO)
        Tomorrow's date (ISO): \(tomorrowISO)

        \(taskContextLines)

        Keep responses short (1–2 sentences). Use plain text — no markdown, no bullets.
        Be warm and direct.

        When the user asks you to create, move, reschedule, or complete a task — do it immediately. Do NOT ask for confirmation. Just do it and briefly say what you did.

        Always append an action block AFTER your response text when performing task operations:
        [ACTIONS]{"actions":[...]}[/ACTIONS]

        Supported action types:
        • Move a task:              {"type":"move_task","title":"exact title","new_time":"HH:MM"}
        • Create a scheduled task:  {"type":"create_task","title":"name","time":"HH:MM","date":"YYYY-MM-DD","duration_minutes":30}
        • Create an UNSCHEDULED task (no time/date known): {"type":"create_unscheduled_task","title":"name","duration_minutes":30}
        • Complete a task:          {"type":"complete_task","title":"exact title"}

        Use 24-hour HH:MM. Default duration 30 min. Always include "date" in create_task using the ISO dates above.
        If the user says "tomorrow", use \(tomorrowISO). If they say "today", use \(todayISO).
        If the user is unsure about the time or says "no time" / "unscheduled" / "backlog" / "later", use create_unscheduled_task.

        PROTECTED tasks (marked [protected]): never include in [ACTIONS]. You may mention them.
        """

        var apiMsgs: [[String: String]] = [["role": "system", "content": system]]
        for msg in messages.suffix(20) where msg.role != "system" {
            apiMsgs.append(["role": msg.role, "content": msg.content])
        }

        Analytics.track(Analytics.Event.aiMessageSent, properties: ["query_length": trimmed.count])

        do {
            let raw = try await AIService.chat(messages: apiMsgs)
            let (displayText, actions) = Self.parseResponse(raw)
            messages.append(ChatMessage(role: "assistant", content: displayText))
            if !actions.isEmpty {
                pendingActions = actions
                Analytics.track(Analytics.Event.aiActionExecuted, properties: ["action_count": actions.count])
            }
        } catch {
            messages.removeLast()
            errorMessage = (error as? AIError)?.errorDescription ?? "Something went wrong."
            Analytics.track(Analytics.Event.aiError, properties: ["error": errorMessage ?? "unknown"])
        }

        isLoading = false
    }

    @MainActor
    func sendSuggestion(_ text: String) {
        Analytics.track(Analytics.Event.aiSuggestionTapped, properties: ["suggestion": text])
        inputText = text
        Task { await send() }
    }

    func clearConversation() {
        Analytics.track(Analytics.Event.aiConversationCleared, properties: ["message_count": messages.count])
        messages.removeAll()
        errorMessage = nil
        pendingActions = []
    }

    // MARK: - Response Parsing

    static func parseResponse(_ raw: String) -> (String, [AIAction]) {
        let open = "[ACTIONS]"
        let close = "[/ACTIONS]"
        guard let openRange = raw.range(of: open),
              let closeRange = raw.range(of: close),
              openRange.upperBound < closeRange.lowerBound else {
            return (raw.trimmingCharacters(in: .whitespacesAndNewlines), [])
        }

        let jsonText = String(raw[openRange.upperBound..<closeRange.lowerBound])
        let displayText = raw[raw.startIndex..<openRange.lowerBound]
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonText.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let actionsArray = json["actions"] as? [[String: Any]] else {
            return (displayText, [])
        }

        let isoFmt = DateFormatter()
        isoFmt.dateFormat = "yyyy-MM-dd"

        let actions: [AIAction] = actionsArray.compactMap { dict in
            guard let type = dict["type"] as? String else { return nil }
            switch type {

            case "move_task":
                guard let title = dict["title"] as? String,
                      let timeStr = dict["new_time"] as? String,
                      let (h, m) = parseTime(timeStr) else { return nil }
                return .moveTask(title: title, hour: h, minute: m)

            case "create_task":
                guard let title = dict["title"] as? String,
                      let timeStr = dict["time"] as? String,
                      let (h, m) = parseTime(timeStr) else { return nil }
                let dur = dict["duration_minutes"] as? Int ?? 30
                // YOH-94: parse optional date field
                let taskDate: Date? = (dict["date"] as? String).flatMap { isoFmt.date(from: $0) }
                return .createTask(title: title, hour: h, minute: m, durationMinutes: dur, date: taskDate)

            // YOH-93: create task with no scheduled time
            case "create_unscheduled_task":
                guard let title = dict["title"] as? String else { return nil }
                let dur = dict["duration_minutes"] as? Int ?? 30
                return .createUnscheduledTask(title: title, durationMinutes: dur)

            case "complete_task":
                guard let title = dict["title"] as? String else { return nil }
                return .completeTask(title: title)

            default: return nil
            }
        }

        return (displayText, actions)
    }

    private static func parseTime(_ s: String) -> (Int, Int)? {
        let parts = s.split(separator: ":").compactMap { Int($0) }
        guard parts.count >= 2 else { return nil }
        return (parts[0], parts[1])
    }
}
