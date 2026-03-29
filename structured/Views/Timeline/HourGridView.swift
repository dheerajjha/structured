import SwiftUI

/// Background hour grid with labels and horizontal lines
struct HourGridView: View {
    let hourHeight: CGFloat = TimelineViewModel.hourHeight

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines and labels
            ForEach(0..<25, id: \.self) { hour in
                HStack(alignment: .top, spacing: 8) {
                    // Hour label
                    Text(TimeFormatting.hourLabel(for: hour % 24))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .frame(width: 48, alignment: .trailing)

                    // Horizontal line
                    VStack {
                        Divider()
                    }
                }
                .offset(y: CGFloat(hour) * hourHeight - 6)
            }
        }
        .frame(height: TimelineViewModel.totalHeight)
    }
}

#Preview {
    ScrollView {
        HourGridView()
    }
}
