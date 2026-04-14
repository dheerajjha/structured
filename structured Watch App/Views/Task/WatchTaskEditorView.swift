import SwiftUI
import SwiftData

struct WatchTaskEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let task: WatchTask?
    let selectedDate: Date
    var startAsInbox: Bool = false

    @State private var title = ""
    @State private var isAllDay = false
    @State private var startTime = Date()
    @State private var durationMinutes: Double = 30
    @State private var colorHex = "#FF6B6B"
    @State private var iconName = "star.fill"

    private var isEditing: Bool { task != nil }

    private let durationOptions: [(String, Double)] = [
        ("15m", 15), ("30m", 30), ("45m", 45),
        ("1h", 60), ("1.5h", 90), ("2h", 120),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    TextField("Task name", text: $title)
                        .font(.footnote)

                    // All Day toggle
                    Toggle("All Day", isOn: $isAllDay)
                        .font(.caption)

                    if !isAllDay && !startAsInbox {
                        // Time picker
                        DatePicker(
                            "Time",
                            selection: $startTime,
                            displayedComponents: .hourAndMinute
                        )
                        .font(.caption)
                    }

                    // Duration
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(durationOptions, id: \.1) { label, mins in
                                    Button {
                                        durationMinutes = mins
                                    } label: {
                                        Text(label)
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(
                                                Capsule()
                                                    .fill(durationMinutes == mins
                                                          ? Color(hex: colorHex)
                                                          : Color(.gray).opacity(0.3))
                                            )
                                            .foregroundStyle(durationMinutes == mins ? .white : .primary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Color
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Color")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(WatchTaskColors.all) { tc in
                                    Button {
                                        colorHex = tc.hex
                                    } label: {
                                        Circle()
                                            .fill(tc.color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(.white, lineWidth: colorHex == tc.hex ? 2 : 0)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle(isEditing ? "Edit" : "New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { loadTaskData() }
        }
    }

    // MARK: - Data Loading

    private func loadTaskData() {
        if let task {
            title = task.title
            isAllDay = task.isAllDay
            startTime = task.startTime ?? selectedDate.atTime(hour: 9)
            durationMinutes = Double(task.durationMinutes)
            colorHex = task.colorHex
            iconName = task.iconName
        } else {
            let calendar = Calendar.current
            let now = Date()
            let minute = calendar.component(.minute, from: now)
            let roundedMinute = ((minute + 14) / 15) * 15
            startTime = calendar.date(bySettingHour: calendar.component(.hour, from: now),
                                       minute: roundedMinute, second: 0, of: selectedDate) ?? selectedDate.atTime(hour: 9)
        }
    }

    // MARK: - Save

    private func saveTask() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespaces)
        guard !trimmedTitle.isEmpty else { return }

        if let task {
            task.title = trimmedTitle
            task.isAllDay = isAllDay
            task.startTime = isAllDay ? nil : startTime
            task.duration = durationMinutes * 60
            task.colorHex = colorHex
            task.iconName = iconName
            task.modifiedAt = Date()
        } else {
            let newTask = WatchTask(
                title: trimmedTitle,
                startTime: (isAllDay || startAsInbox) ? nil : startTime,
                duration: durationMinutes * 60,
                date: selectedDate,
                colorHex: colorHex,
                iconName: iconName,
                isAllDay: isAllDay,
                isInbox: startAsInbox
            )
            modelContext.insert(newTask)
        }

        dismiss()
    }
}
