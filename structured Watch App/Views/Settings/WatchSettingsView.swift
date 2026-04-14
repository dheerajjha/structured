import SwiftUI

struct WatchSettingsView: View {
    @AppStorage("anchor_wake_hour") private var wakeHour = 7
    @AppStorage("anchor_wake_minute") private var wakeMinute = 0
    @AppStorage("anchor_bed_hour") private var bedHour = 23
    @AppStorage("anchor_bed_minute") private var bedMinute = 0

    @State private var wakeTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @State private var bedTime = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date())!

    private let coral = Color(hex: "#E8907E")
    private let slateBlue = Color(hex: "#7C97AB")

    var body: some View {
        NavigationStack {
            List {
                Section("Wake Up") {
                    DatePicker(
                        "Rise and Shine",
                        selection: $wakeTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: wakeTime) { _, newVal in
                        wakeHour = Calendar.current.component(.hour, from: newVal)
                        wakeMinute = Calendar.current.component(.minute, from: newVal)
                    }
                }

                Section("Bedtime") {
                    DatePicker(
                        "Wind Down",
                        selection: $bedTime,
                        displayedComponents: .hourAndMinute
                    )
                    .onChange(of: bedTime) { _, newVal in
                        bedHour = Calendar.current.component(.hour, from: newVal)
                        bedMinute = Calendar.current.component(.minute, from: newVal)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            
            .onAppear {
                wakeTime = Calendar.current.date(bySettingHour: wakeHour, minute: wakeMinute, second: 0, of: Date()) ?? Date()
                bedTime = Calendar.current.date(bySettingHour: bedHour, minute: bedMinute, second: 0, of: Date()) ?? Date()
            }
        }
    }
}
