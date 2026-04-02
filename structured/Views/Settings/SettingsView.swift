import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]

    // Local picker state — loaded from DailyAnchorManager on appear
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: Date())!
    @State private var bedTime:  Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

    // Sheet state
    @State private var showWakePicker = false
    @State private var showBedPicker  = false
    @State private var exportFileURL: URL?
    @State private var showShareSheet = false

    private let coral     = Color(hex: "#E8907E")
    private let slateBlue = Color(hex: "#7C97AB")

    private var timeFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f
    }

    var body: some View {
        NavigationStack {
            List {
                anchorsSection
                exportSection
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                wakeTime = DailyAnchorManager.storedWakeTime()
                bedTime  = DailyAnchorManager.storedBedTime()
            }
            .sheet(isPresented: $showWakePicker) {
                OnboardingTimePickerPage(
                    title: "Change your",
                    highlightedWord: "wake up",
                    subtitle: "Rise and Shine will use this time on new days.",
                    selectedTime: $wakeTime,
                    theme: .morning
                ) {
                    applyTimes()
                    showWakePicker = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showBedPicker) {
                OnboardingTimePickerPage(
                    title: "Change your",
                    highlightedWord: "bedtime",
                    subtitle: "Wind Down will use this time on new days.",
                    selectedTime: $bedTime,
                    theme: .night
                ) {
                    applyTimes()
                    showBedPicker = false
                }
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Anchor Times Section

    private var anchorsSection: some View {
        Section {
            // Wake Up row
            Button { showWakePicker = true } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Wake Up Time")
                                .foregroundStyle(.primary)
                            Text("Rise and Shine default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(coral)
                                .frame(width: 32, height: 32)
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    Text(timeFormatter.string(from: wakeTime))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
            }
            .buttonStyle(.plain)

            // Bedtime row
            Button { showBedPicker = true } label: {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Bedtime")
                                .foregroundStyle(.primary)
                            Text("Wind Down default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(slateBlue)
                                .frame(width: 32, height: 32)
                            Image(systemName: "moon.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    Spacer()
                    Text(timeFormatter.string(from: bedTime))
                        .foregroundStyle(.secondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color(.systemGray3))
                }
            }
            .buttonStyle(.plain)

        } header: {
            Text("Daily Anchors")
        } footer: {
            Text("Rise and Shine and Wind Down appear on every day's timeline at these times. Days you've manually adjusted keep their own time.")
        }
    }

    // MARK: - Data & Export Section

    private var exportSection: some View {
        Section {
            Button { exportCSV() } label: {
                Label("Export to CSV", systemImage: "doc.text")
                    .foregroundStyle(.primary)
            }

            Button { exportICS() } label: {
                Label("Export to iCal (.ics)", systemImage: "calendar")
                    .foregroundStyle(.primary)
            }

            Button {
                // TODO: Google Calendar OAuth
            } label: {
                Label("Sync with Google Calendar", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.secondary)
            }

            Button {
                // TODO: Apple Calendar / EventKit
            } label: {
                Label("Sync with Apple Calendar", systemImage: "apple.logo")
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Data & Export")
        } footer: {
            Text("CSV and iCal export are ready. Calendar sync coming soon.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportFileURL {
                ShareSheet(items: [url])
            }
        }
    }

    // MARK: - CSV Export

    private func exportCSV() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let timeFmt = DateFormatter()
        timeFmt.dateFormat = "HH:mm"

        var csv = "Title,Date,Start Time,Duration (min),Color,Icon,Completed,All Day,Inbox\n"
        for task in allTasks {
            let date = fmt.string(from: task.date)
            let start = task.startTime.map { timeFmt.string(from: $0) } ?? ""
            let dur = task.durationMinutes
            let line = "\"\(task.title)\",\(date),\(start),\(dur),\(task.colorHex),\(task.iconName),\(task.isCompleted),\(task.isAllDay),\(task.isInbox)"
            csv += line + "\n"
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("structured_tasks.csv")
        try? csv.write(to: url, atomically: true, encoding: .utf8)
        exportFileURL = url
        showShareSheet = true
    }

    // MARK: - iCal Export

    private func exportICS() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd'T'HHmmss"
        fmt.timeZone = TimeZone.current

        var ics = "BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//Structured//EN\n"

        for task in allTasks where !task.isInbox {
            guard let start = task.startTime else { continue }
            let end = start.addingTimeInterval(max(task.duration, 900)) // min 15 min
            ics += "BEGIN:VEVENT\n"
            ics += "DTSTART:\(fmt.string(from: start))\n"
            ics += "DTEND:\(fmt.string(from: end))\n"
            ics += "SUMMARY:\(task.title)\n"
            if !task.notes.isEmpty { ics += "DESCRIPTION:\(task.notes.replacingOccurrences(of: "\n", with: "\\n"))\n" }
            ics += "STATUS:\(task.isCompleted ? "COMPLETED" : "CONFIRMED")\n"
            ics += "END:VEVENT\n"
        }

        ics += "END:VCALENDAR\n"

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("structured_tasks.ics")
        try? ics.write(to: url, atomically: true, encoding: .utf8)
        exportFileURL = url
        showShareSheet = true
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
            LabeledContent("AI Model", value: "GPT-4.1 Nano")
        }
    }

    // MARK: - Apply

    private func applyTimes() {
        DailyAnchorManager.saveWakeTime(wakeTime)
        DailyAnchorManager.saveBedTime(bedTime)
        DailyAnchorManager.updateGlobalTimes(
            context: modelContext,
            wakeHour: wakeTime.hour, wakeMinute: wakeTime.minute,
            bedHour: bedTime.hour,   bedMinute: bedTime.minute
        )
    }
}

// MARK: - Share Sheet (UIKit bridge)

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [StructuredTask.self, Subtask.self], inMemory: true)
}
