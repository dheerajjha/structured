import SwiftUI

// MARK: - AI Actions (parsed from model response)

enum AIAction {
    case moveTask(title: String, hour: Int, minute: Int)
    case createTask(title: String, hour: Int, minute: Int, durationMinutes: Int, date: Date?, colorHex: String?)
    case createUnscheduledTask(title: String, durationMinutes: Int, colorHex: String?)
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
            lines.append("Scheduled tasks:")
            for t in scheduledTasks {
                let time      = t.startTime.map { fmt.string(from: $0) } ?? "?"
                let dur       = t.durationMinutes > 0 ? "\(t.durationMinutes) min" : ""
                let done      = t.isCompleted ? " [completed]" : ""
                let prot      = t.isProtected ? " [protected]" : ""
                lines.append("  • title=\"\(t.title)\" | time=\(time) | duration=\(dur) | color=\(t.colorHex)\(done)\(prot)")
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

        let system = String(
            localized: "You are a friendly AI planning assistant in the Tickd daily planner app.\nToday is \(todayStr). Current time is \(nowTimeStr).\nToday's date (ISO): \(todayISO)\nTomorrow's date (ISO): \(tomorrowISO)\n\n\(taskContextLines)\n\nKeep responses short (1–2 sentences). Use plain text — no markdown, no bullets.\nBe warm and direct.\n\nWhen the user asks you to create, move, reschedule, complete, or in any way modify tasks — do it immediately. Do NOT ask for confirmation. Do NOT just describe what you would do. Actually do it by including the [ACTIONS] block.\nWords like \"suggest\", \"can you\", \"would you\", \"please\" are all commands — treat them as direct instructions and execute immediately.\n\nYou MUST append an action block AFTER your response text whenever any task operation is needed:\n[ACTIONS]{\"actions\":[...]}[/ACTIONS]\nNEVER respond about task changes without including [ACTIONS]. If you mention moving, creating, or completing a task, the [ACTIONS] block is mandatory.\n\nSupported action types:\n• Move a task:              {\"type\":\"move_task\",\"title\":\"exact title only\",\"new_time\":\"HH:MM\"}\n• Create a scheduled task:  {\"type\":\"create_task\",\"title\":\"name\",\"time\":\"HH:MM\",\"date\":\"YYYY-MM-DD\",\"duration_minutes\":30,\"color\":\"#HEX\"}\n• Create an UNSCHEDULED task (no time/date known): {\"type\":\"create_unscheduled_task\",\"title\":\"name\",\"duration_minutes\":30,\"color\":\"#HEX\"}\n• Complete a task:          {\"type\":\"complete_task\",\"title\":\"exact title\"}\n\nUse 24-hour HH:MM. Default duration 30 min. Always include \"date\" in create_task using the ISO dates above.\nWhen copying tasks, preserve the original color. Default color is #E8907E if not specified.\nCRITICAL: The \"title\" field must contain ONLY the task name from title=\"...\" — never include duration, time, or other metadata in the title.\nIf the user says \"tomorrow\", use \(tomorrowISO). If they say \"today\", use \(todayISO).\nIf the user is unsure about the time or says \"no time\" / \"unscheduled\" / \"backlog\" / \"later\", use create_unscheduled_task.\n\nPROTECTED tasks (marked [protected]): never include in [ACTIONS]. You may mention them.",
            comment: "AI system prompt — preserve [ACTIONS] markers and JSON format"
        )

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
            errorMessage = (error as? AIError)?.errorDescription ?? String(localized: "Something went wrong.", comment: "Generic AI chat error fallback shown when the proxy fails for an unknown reason")
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
                let color = dict["color"] as? String
                // YOH-94: parse optional date field
                let taskDate: Date? = (dict["date"] as? String).flatMap { isoFmt.date(from: $0) }
                return .createTask(title: title, hour: h, minute: m, durationMinutes: dur, date: taskDate, colorHex: color)

            // YOH-93: create task with no scheduled time
            case "create_unscheduled_task":
                guard let title = dict["title"] as? String else { return nil }
                let dur = dict["duration_minutes"] as? Int ?? 30
                let color = dict["color"] as? String
                return .createUnscheduledTask(title: title, durationMinutes: dur, colorHex: color)

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
