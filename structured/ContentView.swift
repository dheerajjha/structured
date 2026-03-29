import SwiftUI
import SwiftData

/// Root view — shows onboarding on first launch, then day timeline
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var viewModel = TimelineViewModel()
    @State private var showDatePicker = false

    var body: some View {
        if !hasCompletedOnboarding {
            OnboardingContainerView(hasCompletedOnboarding: $hasCompletedOnboarding)
        } else {
        VStack(spacing: 0) {
            // MARK: - Navigation Header
            headerView

            // MARK: - Week Strip
            weekStripView

            Divider()

            // MARK: - Timeline
            DayTimelineView(viewModel: viewModel)
        }
        .overlay(alignment: .bottomTrailing) {
            addButton
        }
        } // else
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            // Date title (tappable for picker)
            Button {
                showDatePicker.toggle()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    if viewModel.isToday {
                        Text("Today")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color(hex: "#FF6B6B"))
                    }
                    Text(viewModel.selectedDate.fullDateString)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker) {
                DatePicker(
                    "Select Date",
                    selection: Binding(
                        get: { viewModel.selectedDate },
                        set: { viewModel.selectDate($0) }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .presentationCompactAdaptation(.popover)
            }

            Spacer()

            // Navigation arrows
            HStack(spacing: 16) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goToPreviousDay()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.semibold))
                }

                Button {
                    viewModel.goToToday()
                } label: {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(viewModel.isToday ? Color(.systemGray5) : Color(hex: "#FF6B6B"))
                        )
                        .foregroundStyle(viewModel.isToday ? Color.secondary : Color.white)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.goToNextDay()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // MARK: - Week Strip

    private var weekStripView: some View {
        let weekDays = viewModel.selectedDate.weekDays

        return HStack(spacing: 0) {
            ForEach(weekDays, id: \.self) { day in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectDate(day)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(day.shortDayName)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)

                        Text("\(day.dayNumber)")
                            .font(.callout.weight(day.isSameDay(as: viewModel.selectedDate) ? .bold : .regular))
                            .foregroundStyle(day.isSameDay(as: viewModel.selectedDate) ? .white : day.isToday ? Color(hex: "#FF6B6B") : .primary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(day.isSameDay(as: viewModel.selectedDate) ? Color(hex: "#FF6B6B") : .clear)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - FAB

    private var addButton: some View {
        Button {
            viewModel.startNewTask()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(Color(hex: "#FF6B6B"))
                        .shadow(color: Color(hex: "#FF6B6B").opacity(0.3), radius: 8, y: 4)
                )
        }
        .padding(.trailing, 20)
        .padding(.bottom, 24)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [StructuredTask.self, Subtask.self], inMemory: true)
}
