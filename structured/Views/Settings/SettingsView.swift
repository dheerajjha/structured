import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext

    // Local picker state — loaded from DailyAnchorManager on appear
    @State private var wakeTime: Date = Calendar.current.date(bySettingHour: 7,  minute: 0, second: 0, of: Date())!
    @State private var bedTime:  Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

    // Sheet state
    @State private var showWakePicker = false
    @State private var showBedPicker  = false

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
            Button {
                // TODO: implement CSV export
            } label: {
                Label("Export to CSV", systemImage: "doc.text")
                    .foregroundStyle(.primary)
            }

            Button {
                // TODO: implement iCal export
            } label: {
                Label("Export to iCal (.ics)", systemImage: "calendar")
                    .foregroundStyle(.primary)
            }

            Button {
                // TODO: implement Google Calendar OAuth + sync
            } label: {
                Label("Sync with Google Calendar", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundStyle(.primary)
            }

            Button {
                // TODO: Apple Calendar / EventKit
            } label: {
                Label("Sync with Apple Calendar", systemImage: "apple.logo")
                    .foregroundStyle(.primary)
            }
        } header: {
            Text("Data & Export")
        } footer: {
            Text("Export and calendar sync coming soon.")
        }
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

#Preview {
    SettingsView()
        .modelContainer(for: [StructuredTask.self, Subtask.self], inMemory: true)
}
