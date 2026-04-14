import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StructuredTask.order) private var allTasks: [StructuredTask]

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
                aboutSection
            }
            .navigationTitle("Settings")
            .onAppear {
                wakeTime = DailyAnchorManager.storedWakeTime()
                bedTime  = DailyAnchorManager.storedBedTime()
                Analytics.track(Analytics.Event.settingsViewed)
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
                    Analytics.track(Analytics.Event.wakeTimeChanged, properties: ["hour": wakeTime.hour, "minute": wakeTime.minute])
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
                    Analytics.track(Analytics.Event.bedTimeChanged, properties: ["hour": bedTime.hour, "minute": bedTime.minute])
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
                        VStack(alignment: .leading, spacing: scaled(2)) {
                            Text("Wake Up Time")
                                .foregroundStyle(.primary)
                            Text("Rise and Shine default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: scaled(8))
                                .fill(coral)
                                .frame(width: scaled(32), height: scaled(32))
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: scaled(14), weight: .semibold))
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
                        VStack(alignment: .leading, spacing: scaled(2)) {
                            Text("Bedtime")
                                .foregroundStyle(.primary)
                            Text("Wind Down default")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        ZStack {
                            RoundedRectangle(cornerRadius: scaled(8))
                                .fill(slateBlue)
                                .frame(width: scaled(32), height: scaled(32))
                            Image(systemName: "moon.fill")
                                .font(.system(size: scaled(14), weight: .semibold))
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

    // MARK: - About Section

    private var aboutSection: some View {
        Section("About") {
            LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
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
