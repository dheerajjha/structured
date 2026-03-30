import SwiftUI

// MARK: - AI Actions (parsed from model response)

enum AIAction {
    case moveTask(title: String, hour: Int, minute: Int)
    case createTask(title: String, hour: Int, minute: Int, durationMinutes: Int)
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
                let time = t.startTime.map { fmt.string(from: $0) } ?? "?"
                let dur  = t.durationMinutes > 0 ? " (\(t.durationMinutes) min)" : ""
                let done = t.isCompleted ? " [completed]" : ""
                lines.append("  • \(time) — \(t.title)\(dur)\(done)")
            }
        }

        if !unscheduledTasks.isEmpty {
            lines.append("Unscheduled backlog:")
            for t in unscheduledTasks {
                let dur = t.durationMinutes > 0 ? " (\(t.durationMinutes) min)" : ""
                lines.append("  • \(t.title)\(dur)")
            }
        }

        if lines.isEmpty { lines = ["No tasks today."] }
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

        let dateStr = Date().formatted(.dateTime.weekday(.wide).month().day().year())

        let system = """
        You are a friendly AI planning assistant in the Structured daily planner app.
        Today is \(dateStr).

        \(taskContextLines)

        Keep responses short (2–4 sentences). Use plain text — no markdown, no bullet symbols.
        Be warm and practical.

        IMPORTANT — when the user confirms they want you to actually modify tasks, append an action block AFTER your response text, on its own line, in this exact format:
        [ACTIONS]{"actions":[...]}[/ACTIONS]

        Supported action types (use exact task titles from the schedule above):
        • Move a task: {"type":"move_task","title":"exact title","new_time":"HH:MM"}
        • Create a task: {"type":"create_task","title":"name","time":"HH:MM","duration_minutes":30}
        • Complete a task: {"type":"complete_task","title":"exact title"}

        Use 24-hour HH:MM format. Only output [ACTIONS] when the user explicitly confirms changes.
        First explain the plan, ask for confirmation, then act when they say yes.
        """

        var apiMsgs: [[String: String]] = [["role": "system", "content": system]]
        for msg in messages.suffix(20) where msg.role != "system" {
            apiMsgs.append(["role": msg.role, "content": msg.content])
        }

        do {
            let raw = try await AIService.chat(messages: apiMsgs)
            let (displayText, actions) = Self.parseResponse(raw)
            messages.append(ChatMessage(role: "assistant", content: displayText))
            if !actions.isEmpty {
                pendingActions = actions
            }
        } catch {
            messages.removeLast()
            errorMessage = (error as? AIError)?.errorDescription ?? "Something went wrong."
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

    static func parseResponse(_ raw: String) -> (String, [AIAction]) {
        // Extract [ACTIONS]...[/ACTIONS] block
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
                return .createTask(title: title, hour: h, minute: m, durationMinutes: dur)

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
