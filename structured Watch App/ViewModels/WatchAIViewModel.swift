import SwiftUI

// MARK: - Watch AI Actions

enum WatchAIAction {
    case moveTask(title: String, hour: Int, minute: Int)
    case createTask(title: String, hour: Int, minute: Int, durationMinutes: Int, date: Date?, colorHex: String?)
    case createUnscheduledTask(title: String, durationMinutes: Int, colorHex: String?)
    case completeTask(title: String)
}

// MARK: - Watch Chat Message

struct WatchChatMessage: Identifiable {
    let id = UUID()
    let role: String
    let content: String
}

// MARK: - Watch AI View Model

@Observable
class WatchAIViewModel {
    var messages: [WatchChatMessage] = []
    var inputText: String = ""
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var pendingActions: [WatchAIAction] = []

    private var taskContextLines: String = "No tasks today."

    // MARK: - Context

    func updateContext(scheduledTasks: [WatchTask], unscheduledTasks: [WatchTask]) {
        let fmt = DateFormatter()
        fmt.dateFormat = "h:mm a"
        var lines: [String] = []

        if !scheduledTasks.isEmpty {
            lines.append("Scheduled tasks:")
            for t in scheduledTasks {
                let time = t.startTime.map { fmt.string(from: $0) } ?? "?"
                let dur  = t.durationMinutes > 0 ? "\(t.durationMinutes) min" : ""
                let done = t.isCompleted ? " [completed]" : ""
                let prot = t.isProtected ? " [protected]" : ""
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

        messages.append(WatchChatMessage(role: "user", content: trimmed))
        inputText = ""
        isLoading = true
        errorMessage = nil

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
        You are a friendly AI planning assistant in the Tickd daily planner app (Apple Watch).
        Today is \(todayStr). Current time is \(nowTimeStr).
        Today's date (ISO): \(todayISO)
        Tomorrow's date (ISO): \(tomorrowISO)

        \(taskContextLines)

        Keep responses very short (1 sentence max). Be warm and direct.

        When the user asks you to create, move, reschedule, complete, or in any way modify tasks — do it immediately. Do NOT ask for confirmation.
        Words like "suggest", "can you", "would you", "please" are all commands — execute immediately.

        You MUST append an action block AFTER your response text whenever any task operation is needed:
        [ACTIONS]{"actions":[...]}[/ACTIONS]
        NEVER respond about task changes without including [ACTIONS].

        Supported action types:
        • Move a task:              {"type":"move_task","title":"exact title only","new_time":"HH:MM"}
        • Create a scheduled task:  {"type":"create_task","title":"name","time":"HH:MM","date":"YYYY-MM-DD","duration_minutes":30,"color":"#HEX"}
        • Create an UNSCHEDULED task: {"type":"create_unscheduled_task","title":"name","duration_minutes":30,"color":"#HEX"}
        • Complete a task:          {"type":"complete_task","title":"exact title"}

        Use 24-hour HH:MM. Default duration 30 min.
        CRITICAL: The "title" field must contain ONLY the task name from title="..." — never include duration, time, or other metadata.
        If the user says "tomorrow", use \(tomorrowISO). If they say "today", use \(todayISO).

        PROTECTED tasks (marked [protected]): never include in [ACTIONS].
        """

        var apiMsgs: [[String: String]] = [["role": "system", "content": system]]
        for msg in messages.suffix(10) where msg.role != "system" {
            apiMsgs.append(["role": msg.role, "content": msg.content])
        }

        do {
            let raw = try await WatchAIService.chat(messages: apiMsgs)
            let (displayText, actions) = Self.parseResponse(raw)
            messages.append(WatchChatMessage(role: "assistant", content: displayText))
            if !actions.isEmpty {
                pendingActions = actions
            }
        } catch {
            messages.removeLast()
            errorMessage = "Something went wrong."
        }

        isLoading = false
    }

    @MainActor
    func sendSuggestion(_ text: String) {
        inputText = text
        Task { await send() }
    }

    func clearConversation() {
        messages.removeAll()
        errorMessage = nil
        pendingActions = []
    }

    // MARK: - Response Parsing

    static func parseResponse(_ raw: String) -> (String, [WatchAIAction]) {
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

        let actions: [WatchAIAction] = actionsArray.compactMap { dict in
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
                let taskDate: Date? = (dict["date"] as? String).flatMap { isoFmt.date(from: $0) }
                return .createTask(title: title, hour: h, minute: m, durationMinutes: dur, date: taskDate, colorHex: color)

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
