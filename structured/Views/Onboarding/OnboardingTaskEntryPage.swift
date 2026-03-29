import SwiftUI

/// Page 6: "What's up next?" — task name entry with suggestions
struct OnboardingTaskEntryPage: View {
    @Binding var taskTitle: String
    @Binding var taskIcon: String

    @FocusState private var isFocused: Bool

    private let coralColor = Color(hex: "#E8907E")

    private let suggestions: [(title: String, icon: String)] = [
        ("Answer Emails", "envelope.fill"),
        ("Clean Up", "sparkles"),
        ("Eat Lunch", "fork.knife"),
        ("Go for a walk", "figure.walk"),
        ("Read a book", "book.fill"),
        ("Exercise", "dumbbell.fill"),
        ("Meeting", "person.2.fill"),
        ("Study", "graduationcap.fill"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            VStack(alignment: .leading, spacing: 8) {
                (Text("What's up ")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                 +
                 Text("next")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(coralColor)
                 +
                 Text("?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)
                )

                Text("Enter something you want to achieve today.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)

            Spacer()

            // Task input card
            HStack(spacing: 12) {
                TaskIconView(iconName: taskIcon, colorHex: coralColor.description, size: 44)

                TextField("Task name", text: $taskTitle)
                    .font(.title3.weight(.medium))
                    .focused($isFocused)
                    .submitLabel(.done)

                if !taskTitle.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(coralColor.opacity(0.5))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(coralColor.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal, 24)

            Spacer()

            // Suggestions
            VStack(alignment: .leading, spacing: 12) {
                Text("Here are some suggestions:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHGrid(rows: [GridItem(.fixed(52)), GridItem(.fixed(52))], spacing: 10) {
                        ForEach(suggestions, id: \.title) { suggestion in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    taskTitle = suggestion.title
                                    taskIcon = suggestion.icon
                                    isFocused = false
                                }
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: suggestion.icon)
                                        .font(.body)
                                        .foregroundStyle(coralColor)

                                    Text(suggestion.title)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(
                                            taskTitle == suggestion.title ? coralColor.opacity(0.5) : Color(.systemGray5),
                                            lineWidth: 1
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .frame(height: 120)
            }

            Spacer(minLength: 20)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isFocused = true
            }
        }
    }
}

#Preview {
    OnboardingTaskEntryPage(taskTitle: .constant(""), taskIcon: .constant("envelope.fill"))
}
