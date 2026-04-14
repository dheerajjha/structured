import SwiftUI
import SwiftData

struct WatchAIView: View {
    @Bindable var viewModel: WatchAIViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WatchTask.order) private var allTasks: [WatchTask]

    private let coral = Color(hex: "#E8907E")

    private var todayScheduled: [WatchTask] {
        allTasks
            .filter { !$0.isInbox && !$0.isAllDay && $0.date.isSameDay(as: Date()) && $0.startTime != nil }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var todayUnscheduled: [WatchTask] {
        allTasks.filter { $0.isInbox }
    }

    private let suggestions: [(icon: String, label: String, prompt: String)] = [
        ("list.bullet", "My day", "What's on my schedule today?"),
        ("clock", "Free time?", "Do I have any free time today?"),
    ]

    var body: some View {
        VStack(spacing: 4) {
            if viewModel.messages.isEmpty {
                emptyState
            } else {
                chatHistory
            }

            if !viewModel.messages.isEmpty {
                Button {
                    viewModel.clearConversation()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            inputBar
        }
            .onChange(of: todayScheduled.count) { _, _ in refreshContext() }
            .onChange(of: todayUnscheduled.count) { _, _ in refreshContext() }
            .onChange(of: viewModel.pendingActions.count) { _, count in
                guard count > 0 else { return }
                executeActions(viewModel.pendingActions)
                viewModel.pendingActions = []
            }
            .onAppear { refreshContext() }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(coral)
            Text("Ask me anything")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                ForEach(suggestions, id: \.label) { s in
                    Button { viewModel.sendSuggestion(s.prompt) } label: {
                        HStack(spacing: 3) {
                            Image(systemName: s.icon)
                                .font(.system(size: 9))
                            Text(s.label)
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(.gray).opacity(0.2)))
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
        }
    }

    // MARK: - Chat History

    private var chatHistory: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(viewModel.messages) { msg in
                        WatchMessageBubble(message: msg, coral: coral)
                            .id(msg.id)
                    }
                    if viewModel.isLoading {
                        HStack {
                            ProgressView()
                                .tint(coral)
                            Spacer()
                        }
                        .id("typing")
                    }
                }
                .padding(.horizontal, 2)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 6) {
            TextField("Ask...", text: $viewModel.inputText)
                .font(.caption)
                .onSubmit { Task { await viewModel.send() } }

            if !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button { Task { await viewModel.send() } } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                        .foregroundStyle(coral)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
            }
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 2)
    }

    // MARK: - Execute Actions

    private func findTask(titled title: String) -> WatchTask? {
        let trimmed = title.trimmingCharacters(in: .whitespaces)
        if let exact = allTasks.first(where: {
            $0.title.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }) { return exact }
        let lower = trimmed.lowercased()
        return allTasks.first(where: {
            $0.title.lowercased().contains(lower) || lower.contains($0.title.lowercased())
        })
    }

    private func executeActions(_ actions: [WatchAIAction]) {
        let cal = Calendar.current
        let today = Date()

        for action in actions {
            switch action {
            case .moveTask(let title, let hour, let minute):
                if let task = findTask(titled: title), !task.isProtected {
                    let base = task.startTime ?? task.date
                    task.startTime = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base)
                    task.modifiedAt = Date()
                    WatchConnectivityManager.shared.sendTaskUpdate("move", taskId: task.id.uuidString, payload: ["hour": hour, "minute": minute])
                }

            case .createTask(let title, let hour, let minute, let duration, let taskDate, let colorHex):
                let targetDay = (taskDate ?? today).startOfDay
                let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: targetDay)
                let newTask = WatchTask(
                    title: title,
                    startTime: start,
                    duration: TimeInterval(duration * 60),
                    date: targetDay,
                    colorHex: colorHex ?? "#E8907E",
                    iconName: "checklist",
                    isAllDay: false
                )
                modelContext.insert(newTask)
                WatchConnectivityManager.shared.sendNewTask(newTask)

            case .createUnscheduledTask(let title, let duration, let colorHex):
                let newTask = WatchTask(
                    title: title,
                    startTime: nil,
                    duration: TimeInterval(duration * 60),
                    date: today.startOfDay,
                    colorHex: colorHex ?? "#E8907E",
                    iconName: "checklist",
                    isAllDay: false,
                    isInbox: true
                )
                modelContext.insert(newTask)
                WatchConnectivityManager.shared.sendNewTask(newTask)

            case .completeTask(let title):
                if let task = findTask(titled: title), !task.isProtected {
                    task.isCompleted = true
                    task.modifiedAt = Date()
                    WatchConnectivityManager.shared.sendTaskUpdate("complete", taskId: task.id.uuidString)
                }
            }
        }

        try? modelContext.save()
    }

    // MARK: - Helpers

    private func refreshContext() {
        viewModel.updateContext(scheduledTasks: todayScheduled, unscheduledTasks: todayUnscheduled)
    }
}

// MARK: - Watch Message Bubble

private struct WatchMessageBubble: View {
    let message: WatchChatMessage
    let coral: Color
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 20) }
            Text(message.content)
                .font(.caption2)
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isUser ? coral.opacity(0.9) : Color(.gray).opacity(0.2))
                )
            if !isUser { Spacer(minLength: 20) }
        }
    }
}
