import SwiftUI

// MARK: - Piano Week Overview

struct PianoWeekView: View {
    let weekDays: [Date]
    let tasks: [StructuredTask]
    let selectedDate: Date

    private let startHour  = 5
    private let endHour    = 25   // 1 AM next day
    private let minuteHeight: CGFloat = scaled(1.0)   // pt per minute → scrollable

    private var totalMinutes: CGFloat { CGFloat((endHour - startHour) * 60) }
    private var totalHeight: CGFloat { totalMinutes * minuteHeight }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: scaled(3)) {
                // Time gutter
                timeGutter
                    .frame(width: scaled(24), height: totalHeight)

                // Day columns (density dots are inside each column header)
                ForEach(weekDays, id: \.self) { day in
                    PianoDayColumn(
                        day: day,
                        tasks: tasksFor(day),
                        isSelected: day.isSameDay(as: selectedDate),
                        totalHeight: totalHeight,
                        startHour: startHour,
                        minuteHeight: minuteHeight
                    )
                    .frame(height: totalHeight)
                }
            }
            .padding(.horizontal, scaled(6))
        }
    }

    // MARK: - Time Gutter

    private var timeGutter: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(stride(from: startHour, through: endHour - 1, by: 3)), id: \.self) { hour in
                let y = CGFloat((hour - startHour) * 60) * minuteHeight
                Text(hourLabel(hour))
                    .font(.system(size: scaled(8), weight: .medium, design: .monospaced))
                    .foregroundStyle(Color(.systemGray3))
                    .position(x: scaled(12), y: y)
            }
        }
    }

    // MARK: - Helpers

    private func hourLabel(_ h: Int) -> String {
        let hNorm = h % 24
        if hNorm == 0 { return "12a" }
        if hNorm == 12 { return "12p" }
        return hNorm < 12 ? "\(hNorm)a" : "\(hNorm - 12)p"
    }

    private func tasksFor(_ day: Date) -> [StructuredTask] {
        tasks.filter {
            $0.date.isSameDay(as: day) && !$0.isInbox && !$0.isAllDay && $0.startTime != nil
        }
        .sorted { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }
    }
}

// MARK: - Single Day Column

private struct PianoDayColumn: View {
    let day: Date
    let tasks: [StructuredTask]
    let isSelected: Bool
    let totalHeight: CGFloat
    let startHour: Int
    let minuteHeight: CGFloat

    var body: some View {
        GeometryReader { geo in
            let colWidth = geo.size.width

            ZStack(alignment: .top) {
                // Column background
                RoundedRectangle(cornerRadius: scaled(10))
                    .fill(isSelected
                          ? Color(.systemGray5).opacity(0.7)
                          : Color(.systemGray6).opacity(0.4))

                // Solid connecting line
                connectingLine

                // Task capsules
                ForEach(tasks) { task in
                    capsule(for: task, colWidth: colWidth)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Connecting Line

    @ViewBuilder
    private var connectingLine: some View {
        if tasks.count >= 2, let first = tasks.first, let last = tasks.last {
            let topY = yPos(for: first) + height(for: first) / 2
            let botY = yPos(for: last) + height(for: last) / 2
            if botY > topY {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: topY))
                    p.addLine(to: CGPoint(x: 0, y: botY))
                }
                .stroke(Color(hex: first.colorHex).opacity(0.2), lineWidth: scaled(2))
                .frame(width: scaled(2))
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Capsule

    private func capsule(for task: StructuredTask, colWidth: CGFloat) -> some View {
        let y = yPos(for: task)
        let h = height(for: task)
        let color = Color(hex: task.colorHex)
        let w = colWidth * 0.82
        let radius: CGFloat = h > scaled(36) ? scaled(16) : h / 2

        return ZStack {
            RoundedRectangle(cornerRadius: radius)
                .fill(color)
                .shadow(color: color.opacity(0.25), radius: scaled(3), y: scaled(2))

            Image(systemName: task.iconName)
                .font(.system(size: min(h * 0.38, scaled(16)), weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: w, height: max(h, scaled(22)))
        .position(x: colWidth / 2, y: y + max(h, scaled(22)) / 2)
    }

    // MARK: - Position Math

    private func yPos(for task: StructuredTask) -> CGFloat {
        guard let start = task.startTime else { return 0 }
        let cal = Calendar.current
        let h = cal.component(.hour, from: start)
        let m = cal.component(.minute, from: start)
        return max(CGFloat((h - startHour) * 60 + m) * minuteHeight, 0)
    }

    private func height(for task: StructuredTask) -> CGFloat {
        max(CGFloat(task.durationMinutes), 20) * minuteHeight
    }
}
