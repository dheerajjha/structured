import SwiftUI
import SwiftData

// MARK: - AI View

struct AIView: View {
    @Bindable var viewModel: AIViewModel   // owned by ContentView — survives tab switches

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]
    @FocusState private var inputFocused: Bool
    @State private var speechRecognizer = SpeechRecognizer()

    private let coral = Color(hex: "#E8907E")

    // MARK: - Task filtering

    private var todayScheduled: [StructuredTask] {
        allTasks
            .filter { !$0.isInbox && !$0.isAllDay && $0.date.isSameDay(as: Date()) && $0.startTime != nil }
            .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }

    private var todayUnscheduled: [StructuredTask] {
        allTasks.filter { $0.isInbox }
    }

    // MARK: - Greeting

    private var greeting: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "Good morning!" }
        if h < 17 { return "Hi there!" }
        return "Good evening!"
    }

    private var greetingSubtitle: String {
        let h = Calendar.current.component(.hour, from: Date())
        if h < 12 { return "What's on the agenda today?" }
        if h < 17 { return "What do you have planned for the day?" }
        return "How did your day go?"
    }

    // MARK: - Suggestions

    private let suggestions: [(icon: String, label: String, prompt: String)] = [
        ("clock.arrow.circlepath", "Move task by 1h",   "Can you suggest moving all my tasks today forward by 1 hour?"),
        ("list.bullet.rectangle",  "Summarize my day",  "Give me a quick summary of what I have planned today."),
        ("sparkles",               "Optimize schedule", "Looking at my tasks, how can I arrange my day more efficiently?"),
        ("clock",                  "Free time today?",  "Do I have any free time blocks today?"),
    ]

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGroupedBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                Divider()

                if viewModel.messages.isEmpty {
                    emptyState
                } else {
                    chatHistory
                }

                if let err = viewModel.errorMessage {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                }

                suggestionRow
                inputBar.padding(.bottom, 8)
            }
        }
        .onChange(of: todayScheduled.count)   { _, _ in refreshContext() }
        .onChange(of: todayUnscheduled.count) { _, _ in refreshContext() }
        .onChange(of: viewModel.pendingActions.count) { _, count in
            guard count > 0 else { return }
            executeActions(viewModel.pendingActions)
            viewModel.pendingActions = []
        }
        .onAppear { refreshContext() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(coral)
                Text(greetingSubtitle)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
            }
            Spacer()
            Button {
                withAnimation { viewModel.clearConversation() }
            } label: {
                Image(systemName: viewModel.messages.isEmpty ? "questionmark" : "arrow.counterclockwise")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(viewModel.messages.isEmpty ? Color.primary : Color.blue)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
                    )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack {
            Spacer()
            Text("Ask me anything about your day.")
                .font(.subheadline)
                .foregroundStyle(Color(.systemGray3))
            Spacer()
        }
    }

    // MARK: - Chat History

    private var chatHistory: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { msg in
                        MessageBubble(message: msg, coral: coral)
                            .id(msg.id)
                    }
                    if viewModel.isLoading {
                        TypingIndicator(coral: coral).id("typing")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    proxy.scrollTo(viewModel.messages.last?.id, anchor: .bottom)
                }
            }
            .onChange(of: viewModel.isLoading) { _, loading in
                if loading { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    // MARK: - Suggestion Chips

    private var suggestionRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(suggestions, id: \.label) { s in
                    Button { viewModel.sendSuggestion(s.prompt) } label: {
                        HStack(spacing: 6) {
                            Image(systemName: s.icon)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(coral)
                            Text(s.label)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                TextField("Tell me your plans...", text: $viewModel.inputText, axis: .vertical)
                    .font(.subheadline)
                    .lineLimit(1...4)
                    .focused($inputFocused)
                    .onSubmit { Task { await viewModel.send() } }

                // Mic button — tap to start/stop speech recognition
                Button {
                    Task { await speechRecognizer.toggle() }
                } label: {
                    Image(systemName: speechRecognizer.isListening ? "mic.fill" : "mic")
                        .font(.body)
                        .foregroundStyle(speechRecognizer.isListening ? coral : Color(.systemGray3))
                        .symbolEffect(.pulse, isActive: speechRecognizer.isListening)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(speechRecognizer.isListening ? coral.opacity(0.5) : .clear, lineWidth: 1.5)
                    )
            )

            // Send button — visible when there's text
            if !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button { Task { await viewModel.send() } } label: {
                    Image(systemName: "arrow.up")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(coral))
                }
                .disabled(viewModel.isLoading)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.snappy(duration: 0.2), value: viewModel.inputText.isEmpty)
        .padding(.horizontal, 16)
        // Sync live transcript into the input field
        .onChange(of: speechRecognizer.transcript) { _, text in
            if !text.isEmpty { viewModel.inputText = text }
        }
        // When speech stops, auto-send if there's content
        .onChange(of: speechRecognizer.isListening) { _, listening in
            if !listening && !viewModel.inputText.trimmingCharacters(in: .whitespaces).isEmpty {
                Task { await viewModel.send() }
            }
        }
    }

    // MARK: - Execute Actions

    private func executeActions(_ actions: [AIAction]) {
        let cal = Calendar.current
        let today = Date()

        for action in actions {
            switch action {

            case .moveTask(let title, let hour, let minute):
                if let task = allTasks.first(where: {
                    $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
                }), !task.isProtected {
                    let base = task.startTime ?? task.date
                    task.startTime = cal.date(bySettingHour: hour, minute: minute, second: 0, of: base)
                }

            case .createTask(let title, let hour, let minute, let duration):
                let start = cal.date(bySettingHour: hour, minute: minute, second: 0, of: today)
                let newTask = StructuredTask(
                    title: title,
                    startTime: start,
                    duration: TimeInterval(duration * 60),
                    date: today.startOfDay,
                    colorHex: "#E8907E",
                    iconName: "star.fill",
                    isAllDay: false
                )
                modelContext.insert(newTask)

            case .completeTask(let title):
                if let task = allTasks.first(where: {
                    $0.title.localizedCaseInsensitiveCompare(title) == .orderedSame
                }), !task.isProtected {
                    task.isCompleted = true
                }
            }
        }
    }

    // MARK: - Helpers

    private func refreshContext() {
        viewModel.updateContext(scheduledTasks: todayScheduled, unscheduledTasks: todayUnscheduled)
    }
}

// MARK: - Message Bubble

private struct MessageBubble: View {
    let message: ChatMessage
    let coral: Color
    private var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }
            Text(message.content)
                .font(.subheadline)
                .foregroundStyle(isUser ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isUser ? coral.opacity(0.9) : Color(.systemBackground))
                        .shadow(color: .black.opacity(isUser ? 0 : 0.05), radius: 4, y: 1)
                )
                .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    let coral: Color
    @State private var phase = 0

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .fill(coral.opacity(0.6))
                        .frame(width: 7, height: 7)
                        .scaleEffect(phase == i ? 1.3 : 0.8)
                        .animation(
                            .easeInOut(duration: 0.4).repeatForever().delay(Double(i) * 0.15),
                            value: phase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 4, y: 1)
            )
            Spacer()
        }
        .onAppear { withAnimation { phase = 1 } }
    }
}
