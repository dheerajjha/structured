import SwiftUI

/// Red line showing the current time on the timeline
struct CurrentTimeIndicatorView: View {
    let timelineWidth: CGFloat

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            let now = context.date
            let y = TimelineViewModel.yPosition(for: now)

            HStack(spacing: 0) {
                // Red dot on the left
                Circle()
                    .fill(.red)
                    .frame(width: 10, height: 10)

                // Red line extending full width
                Rectangle()
                    .fill(.red)
                    .frame(height: 1.5)
            }
            .offset(y: y)
        }
    }
}

#Preview {
    CurrentTimeIndicatorView(timelineWidth: 300)
        .frame(height: 200)
}
