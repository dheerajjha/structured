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
    @State private var taskDate: Date = Date()
    @State private var isAllDay = false
    @State private var startTime = Date()
    @State private var durationMinutes: Double = 30
    @State private var colorHex = TaskColors.default.hex
    @State private var iconName = "checklist"
    @State private var notes = ""
    @State private var subtaskTexts: [String] = []

    // Scheduling state (Option C)
    @State private var isScheduled: Bool = true

    // Custom duration state
    @State private var showCustomDuration = false
    @State private var customHours: Int = 0
    @State private var customMinutes: Int = 0

    // Sheet state
    @State private var showIconPicker = false
    @State private var showDatePicker = false
    @State private var userPickedIcon = false

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
                    HStack(spacing: scaled(12)) {
                        Button {
                            showIconPicker = true
                            userPickedIcon = true
                            Analytics.track(Analytics.Event.iconPickerOpened)
                        } label: {
                            TaskIconView(iconName: iconName, colorHex: colorHex, size: scaled(44))
                        }
                        .buttonStyle(.plain)

                        TextField("Task name", text: $title)
                            .font(.title3.weight(.semibold))
                            .characterLimit($title, max: TaskTextLimit.title)
                            .onChange(of: title) { _, newTitle in
                                guard !userPickedIcon, !isEditing else { return }
                                if let predicted = IconPredictor.predict(for: newTitle) {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        iconName = predicted
                                    }
                                } else {
                                    withAnimation(.snappy(duration: 0.2)) {
                                        iconName = "checklist"
                                    }
                                }
                            }
                    }
                }

                // Color
                Section("Color") {
                    TaskColorPickerView(selectedHex: $colorHex)
                }

                // Date
                if !startAsInbox {
                    Section {
                        HStack {
                            Button {
                                withAnimation(.snappy(duration: 0.25)) {
                                    showDatePicker.toggle()
                                }
                            } label: {
                                Label {
                                    Text("Date")
                                        .foregroundStyle(.primary)
                                } icon: {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(Color(hex: colorHex))
                                }
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            // Quick pills
                            HStack(spacing: scaled(6)) {
                                quickDatePill("Today", date: Date().startOfDay, isActive: Calendar.current.isDateInToday(taskDate))
                                quickDatePill("Tomorrow", date: Date().startOfDay.nextDay, isActive: Calendar.current.isDateInTomorrow(taskDate))
                            }

                            if !Calendar.current.isDateInToday(taskDate) && !Calendar.current.isDateInTomorrow(taskDate) {
                                Text(taskDateLabel)
                                    .font(.caption.weight(.medium))
                                    .foregroundStyle(Color(hex: colorHex))
                            }

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color(.systemGray3))
                                .rotationEffect(.degrees(showDatePicker ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.snappy(duration: 0.25)) {
                                showDatePicker.toggle()
                            }
                        }

                        if showDatePicker {
                            DatePicker(
                                "Select date",
                                selection: $taskDate,
                                in: Date().startOfDay...,
                                displayedComponents: .date
                            )
                            .datePickerStyle(.graphical)
                            .tint(Color(hex: colorHex))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                            .onChange(of: taskDate) { _, _ in
                                withAnimation(.snappy(duration: 0.25)) {
                                    showDatePicker = false
                                }
                            }
                        }
                    }
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
                Section(startAsInbox ? "Duration" : "Time") {
                    if !startAsInbox {
                        Toggle("All Day", isOn: $isAllDay)
                    }

                    if !startAsInbox && !isAllDay {
                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                    }

                        VStack(alignment: .leading, spacing: scaled(8)) {
                            Text("Duration")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: scaled(8)) {
                                    customPill

                                    ForEach(durationOptions, id: \.1) { label, mins in
                                        Button {
                                            withAnimation(.snappy(duration: 0.2)) {
                                                durationMinutes = mins
                                                showCustomDuration = false
                                            }
                                            Analytics.track(Analytics.Event.durationSelected, properties: ["minutes": mins])
                                        } label: {
                                            Text(label)
                                                .font(.subheadline.weight(.medium))
                                                .padding(.horizontal, scaled(12))
                                                .padding(.vertical, scaled(6))
                                                .background(
                                                    Capsule()
                                                        .fill(!showCustomDuration && durationMinutes == mins
                                                              ? Color(hex: colorHex)
                                                              : Color(.systemGray5))
                                                )
                                                .foregroundStyle(!showCustomDuration && durationMinutes == mins ? .white : .primary)
                                        }
                                        .buttonStyle(.plain)
                                    }

                                    customPill
                                }
                            }

                            if showCustomDuration {
                                VStack(spacing: scaled(12)) {
                                    HStack(spacing: scaled(16)) {
                                        HStack(spacing: scaled(4)) {
                                            Picker("Hours", selection: $customHours) {
                                                ForEach(0...8, id: \.self) { h in
                                                    Text("\(h)").tag(h)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                            .frame(width: scaled(60), height: scaled(100))
                                            .clipped()
                                            Text("hr")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        HStack(spacing: scaled(4)) {
                                            Picker("Minutes", selection: $customMinutes) {
                                                ForEach(Array(stride(from: 0, through: 55, by: 5)), id: \.self) { m in
                                                    Text("\(m)").tag(m)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                            .frame(width: scaled(60), height: scaled(100))
                                            .clipped()
                                            Text("min")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Button {
                                        withAnimation(.snappy(duration: 0.2)) {
                                            syncCustomDuration()
                                            showCustomDuration = false
                                        }
                                        Analytics.track(Analytics.Event.durationSelected, properties: ["minutes": durationMinutes])
                                    } label: {
                                        Text("Done — \(customDurationLabel)")
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, scaled(10))
                                            .background(
                                                RoundedRectangle(cornerRadius: scaled(10))
                                                    .fill(Color(hex: colorHex))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(scaled(12))
                                .background(
                                    RoundedRectangle(cornerRadius: scaled(12))
                                        .fill(Color(.systemGray6))
                                )
                                .onChange(of: customHours) { _, _ in syncCustomDuration() }
                                .onChange(of: customMinutes) { _, _ in syncCustomDuration() }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                }

                // Notes section
                Section("Notes") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                        .characterLimit($notes, max: TaskTextLimit.notes)
                }

                // Subtasks section
                Section("Subtasks") {
                    ForEach(subtaskTexts.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            TextField("Subtask", text: $subtaskTexts[index])
                                .characterLimit($subtaskTexts[index], max: TaskTextLimit.subtask)

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
            .presentationDetents([.large])
            .presentationSizing(.form)
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

    // MARK: - Custom Duration Pill

    private var isCustomActive: Bool {
        showCustomDuration || !isPresetDuration
    }

    private var customPill: some View {
        Button {
            withAnimation(.snappy(duration: 0.2)) {
                showCustomDuration.toggle()
                if showCustomDuration {
                    customHours = Int(durationMinutes) / 60
                    customMinutes = Int(durationMinutes) % 60
                }
            }
        } label: {
            Text(isCustomActive ? customDurationLabel : "Custom")
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, scaled(12))
                .padding(.vertical, scaled(6))
                .background(
                    Capsule()
                        .fill(isCustomActive
                              ? Color(hex: colorHex)
                              : Color(.systemGray5))
                )
                .foregroundStyle(isCustomActive ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Date Label

    private var taskDateLabel: String {
        if Calendar.current.isDateInToday(taskDate) {
            return "Today"
        } else if Calendar.current.isDateInTomorrow(taskDate) {
            return "Tomorrow"
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "EEE, d MMM"
            return fmt.string(from: taskDate)
        }
    }

    // MARK: - Quick Date Pill

    private func quickDatePill(_ label: String, date: Date, isActive: Bool) -> some View {
        Button {
            taskDate = date
            withAnimation(.snappy(duration: 0.25)) {
                showDatePicker = false
            }
        } label: {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, scaled(10))
                .padding(.vertical, scaled(4))
                .background(
                    Capsule()
                        .fill(isActive ? Color(hex: colorHex) : Color(.systemGray5))
                )
                .foregroundStyle(isActive ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Custom Duration Helpers

    private var customDurationLabel: String {
        let totalMins = customHours * 60 + customMinutes
        if totalMins == 0 { return "0 min" }
        if customHours > 0 && customMinutes > 0 {
            return "\(customHours) hr \(customMinutes) min"
        } else if customHours > 0 {
            return "\(customHours) hr"
        } else {
            return "\(customMinutes) min"
        }
    }

    private var isPresetDuration: Bool {
        durationOptions.contains { $0.1 == durationMinutes }
    }

    private func syncCustomDuration() {
        let total = Double(customHours * 60 + customMinutes)
        if total > 0 {
            durationMinutes = total
        }
    }

    // MARK: - Data Loading

    private func loadTaskData() {
        taskDate = selectedDate
        if let task {
            title = task.title
            taskDate = task.date
            isAllDay = task.isAllDay
            isScheduled = !task.isInbox
            startTime = task.startTime ?? selectedDate.atTime(hour: 9)
            durationMinutes = Double(task.durationMinutes)
            colorHex = task.colorHex
            // If loaded duration isn't a preset, open custom picker
            if !isPresetDuration {
                showCustomDuration = true
                customHours = Int(durationMinutes) / 60
                customMinutes = Int(durationMinutes) % 60
            }
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
            task.date = taskDate
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
                date: taskDate,
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

        NotificationCenter.default.post(name: .watchSyncNeeded, object: nil)
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
