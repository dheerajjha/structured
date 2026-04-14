import SwiftUI

/// Grid of preset colors for task customization
struct TaskColorPickerView: View {
    @Binding var selectedHex: String

    private let columns = Array(repeating: GridItem(.flexible(), spacing: scaled(12)), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: scaled(12)) {
            ForEach(TaskColors.all) { taskColor in
                Button {
                    selectedHex = taskColor.hex
                    Analytics.track(Analytics.Event.colorSelected, properties: ["color": taskColor.hex])
                } label: {
                    Circle()
                        .fill(taskColor.color)
                        .frame(width: scaled(36), height: scaled(36))
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: selectedHex == taskColor.hex ? scaled(3) : 0)
                        )
                        .overlay(
                            Circle()
                                .strokeBorder(taskColor.color.opacity(0.5), lineWidth: selectedHex == taskColor.hex ? 1 : 0)
                                .padding(-1)
                        )
                        .scaleEffect(selectedHex == taskColor.hex ? 1.1 : 1.0)
                }
                .buttonStyle(.plain)
                .animation(.snappy(duration: 0.2), value: selectedHex)
            }
        }
    }
}

#Preview {
    TaskColorPickerView(selectedHex: .constant("#FF6B6B"))
        .padding()
}
