import SwiftUI
import SwiftData

/// Create or edit a task — presented as a sheet
struct TaskEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: StructuredTask?
    let selectedDate: Date
    var startAsInbox: Bool = false
    var presetStartTime: Date? = nil

    // Form state
    @State private var title = ""
    @State private var isAllDay = false
    @State private var startTime = Date()
    @State private var durationMinutes: Double = 30
    @State private var colorHex = TaskColors.default.hex
    @State private var iconName = "star.fill"
    @State private var notes = ""
    @State private var subtaskTexts: [String] = []

    // Scheduling state (Option C)
    @State private var isScheduled: Bool = true

    // Sheet state
    @State private var showIconPicker = false

    private var isEditing: Bool { task != nil }

    // MARK: - Duration Options

    private let durationOptions: [(String, Double)] = [
        ("15 min", 15),
        ("30 min", 30),
        ("45 min", 45),
        ("1 hr", 60),
        ("1.5 hr", 90),
        ("2 hr", 120),
        ("3 hr", 180),
        ("4 hr", 240),
    ]

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                // Title section
                Section {
                    HStack(spacing: 12) {
                        Button {
                            showIconPicker = true
                            Analytics.track(Analytics.Event.iconPickerOpened)
                        } label: {
                            TaskIconView(iconName: iconName, colorHex: colorHex, size: 44)
                        }
                        .buttonStyle(.plain)

                        TextField("Task name", text: $title)
                            .font(.title3.weight(.semibold))
                    }
                }

                // Color
                Section("Color") {
                    TaskColorPickerView(selectedHex: $colorHex)
                }

                // Option C — Scheduled toggle (editing only)
                if isEditing {
                    Section {
                        Toggle("Scheduled on timeline", isOn: $isScheduled)
                            .tint(Color(hex: colorHex))
                    } footer: {
                        if !isScheduled {
                            Text("Task will move to Unscheduled.")
                                .font(.caption)
                        }
                    }
                }

                // Time section
                Section("Time") {
                    Toggle("All Day", isOn: $isAllDay)

                    if !isAllDay {
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(durationOptions, id: \.1) { label, mins in
                                        Button {
                                            durationMinutes = mins
                                            Analytics.track(Analytics.Event.durationSelected, properties: ["minutes": mins])
                                        } label: {
                                            Text(label)
                                                .font(.subheadline.weight(.medium))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    Capsule()
                                                        .fill(durationMinutes == mins
                                                              ? Color(hex: colorHex)
                                                              : Color(.systemGray5))
                                                )
                                                .foregroundStyle(durationMinutes == mins ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                }

                // Notes section
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }

                // Subtasks section
                Section("Subtasks") {
                    ForEach(subtaskTexts.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            TextField("Subtask", text: $subtaskTexts[index])

                            Button {
                                subtaskTexts.remove(at: index)
                                Analytics.track(Analytics.Event.subtaskRemoved)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        subtaskTexts.append("")
                        Analytics.track(Analytics.Event.subtaskAdded)
                    } label: {
                        Label("Add Subtask", systemImage: "plus.circle.fill")
                            .foregroundStyle(Color(hex: colorHex))
                    }
                }

                // Delete button (editing only)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            deleteTask()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Task")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Task" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .sheet(isPresented: $showIconPicker) {
                IconPickerView(selectedIcon: $iconName)
                    .presentationDetents([.medium, .large])
            }
            .onAppear {
                loadTaskData()
                Analytics.track(Analytics.Event.taskEditorOpened, properties: [
                    "mode": isEditing ? "edit" : "create",
                    "source": startAsInbox ? "inbox" : "timeline"
                ])
            }
        }
    }

    // MARK: - Data Loading

    private func loadTaskData() {
        if let task {
            title = task.title
            isAllDay = task.isAllDay
            isScheduled = !task.isInbox
            startTime = task.startTime ?? selectedDate.atTime(hour: 9)
            durationMinutes = Double(task.durationMinutes)
            colorHex = task.colorHex
            iconName = task.iconName
            notes = task.notes
            subtaskTexts = task.sortedSubtasks.map(\.title)
        } else {
            // Defaults for new task
            if let preset = presetStartTime {
                startTime = preset
            } else {
                let calendar = Calendar.current
                let now = Date()
                let minute = calendar.component(.minute, from: now)
                let roundedMinute = ((minute + 14) / 15) * 15
                startTime = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                           minute: roundedMinute, second: 0, of: selectedDate) ?? selectedDate.atTime(hour: 9)
            }
        }
    }

    // MARK: - Save

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        if let task {
            // Update existing — scheduling always moves out of inbox
            task.title = trimmedTitle
            task.isAllDay = isAllDay
            task.startTime = isAllDay ? nil : startTime
            task.duration = durationMinutes * 60
            task.colorHex = colorHex
            task.iconName = iconName
            task.notes = notes
            task.isInbox = !isScheduled
            if !isScheduled { task.startTime = nil }
            // If user manually changed an anchor task's time, flag it so global updates skip it
            if task.isProtected { task.isUserModifiedTime = true }
            updateSubtasks(for: task)
            Analytics.track(Analytics.Event.taskUpdated, properties: [
                "has_notes": !notes.isEmpty,
                "is_all_day": isAllDay,
                "duration_minutes": durationMinutes,
                "color": colorHex,
                "subtask_count": subtaskTexts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count,
                "is_scheduled": isScheduled
            ])
        } else {
            // Create new
            let newTask = StructuredTask(
                title: trimmedTitle,
                startTime: isAllDay ? nil : startTime,
                duration: durationMinutes * 60,
                date: selectedDate,
                colorHex: colorHex,
                iconName: iconName,
                isAllDay: isAllDay,
                isInbox: startAsInbox
            )
            newTask.notes = notes
            modelContext.insert(newTask)
            updateSubtasks(for: newTask)
            Analytics.track(Analytics.Event.taskCreated, properties: [
                "has_notes": !notes.isEmpty,
                "is_all_day": isAllDay,
                "is_inbox": startAsInbox,
                "duration_minutes": durationMinutes,
                "color": colorHex,
                "subtask_count": subtaskTexts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            ])
        }

        dismiss()
    }

    private func updateSubtasks(for task: StructuredTask) {
        // Remove existing subtasks
        for subtask in task.subtasks ?? [] {
            modelContext.delete(subtask)
        }

        // Add new subtasks
        let validSubtasks = subtaskTexts.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        var newSubtasks: [Subtask] = []
        for (index, text) in validSubtasks.enumerated() {
            let subtask = Subtask(title: text, order: index)
            subtask.task = task
            modelContext.insert(subtask)
            newSubtasks.append(subtask)
        }
        task.subtasks = newSubtasks
    }

    // MARK: - Delete

    private func deleteTask() {
        if let task {
            Analytics.track(Analytics.Event.taskDeleted, properties: ["source": "editor"])
            modelContext.delete(task)
        }
        dismiss()
    }
}
