import SwiftUI

/// Page 5: "What's up next?" — task name with suggestion chips
struct OnboardingTaskEntryPage: View {
    @Binding var taskTitle: String
    @Binding var taskIcon: String
    var onContinue: (@MainActor () -> Void)? = nil

    @FocusState private var focused: Bool

    private let coralHex = "#D4806E"
    private let coral = Color(hex: "#D4806E")
    private let warmBrown = Color(hex: "#8B7355")

    // The English titles act as both display labels (looked up in the catalog
    // via LocalizedStringKey) and as the persisted task title when the user
    // taps a chip. We localize the persisted value with String(localized:) so
    // tapping a chip on a French device saves the French task name.
    private let suggestions: [(title: String, icon: String)] = [
        ("Answer Emails", "envelope.fill"),
        ("Clean Up",      "sparkles"),
        ("Eat Lunch",     "fork.knife"),
        ("Go for a walk", "figure.walk"),
        ("Read a book",   "book.fill"),
        ("Exercise",      "dumbbell.fill"),
        ("Study",         "graduationcap.fill"),
        ("Meeting",       "person.2.fill"),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#F5F0EB").ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: scaled(80))

                // Title
                VStack(alignment: .leading, spacing: scaled(6)) {
                    (Text("What's up ", comment: "Onboarding page 5 title — first segment (before the colored word 'next'). Concatenated as: 'What's up next?'")
                        .foregroundStyle(Color(hex: "#3D3D3D"))
                     + Text("next", comment: "Onboarding page 5 title — colored middle segment. Concatenated as: 'What's up next?'")
                        .foregroundStyle(coral)
                     + Text("?", comment: "Trailing punctuation for onboarding page 5 title (e.g. 'What's up next?')")
                        .foregroundStyle(Color(hex: "#3D3D3D"))
                    )
                    .font(.system(size: scaled(32), weight: .bold))

                    Text("Enter something you want to achieve today.", comment: "Onboarding page 5 subtitle below the title")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, scaled(24))

                Spacer().frame(height: scaled(32))

                // Task name input
                HStack(spacing: scaled(12)) {
                    TaskIconView(iconName: taskIcon, colorHex: coralHex, size: scaled(44))

                    TextField("Task name", text: $taskTitle)
                        .font(.title3.weight(.medium))
                        .focused($focused)
                        .submitLabel(.done)
                        .characterLimit($taskTitle, max: TaskTextLimit.title)

                    if !taskTitle.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(coral.opacity(0.5))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(scaled(16))
                .background(RoundedRectangle(cornerRadius: scaled(16)).fill(.white).shadow(color: .black.opacity(0.05), radius: scaled(8), y: scaled(2)))
                .overlay(RoundedRectangle(cornerRadius: scaled(16)).strokeBorder(coral.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, scaled(24))

                Spacer().frame(height: scaled(28))

                // Suggestions grid — all visible, no scrolling
                VStack(alignment: .leading, spacing: scaled(10)) {
                    Text("Suggestions:", comment: "Label above the grid of task-name suggestion chips during onboarding")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: scaled(10)
                    ) {
                        ForEach(suggestions, id: \.title) { s in
                            Button {
                                withAnimation(.snappy(duration: 0.2)) {
                                    // Persist the locale-appropriate task title so the user's
                                    // saved task is rendered in their language.
                                    taskTitle = String(localized: String.LocalizationValue(s.title), comment: "Onboarding task suggestion chip — also persisted as the user's first task title")
                                    taskIcon  = s.icon
                                    focused   = false
                                }
                            } label: {
                                HStack(spacing: scaled(8)) {
                                    Image(systemName: s.icon)
                                        .font(.subheadline)
                                        .foregroundStyle(coral)
                                    Text(LocalizedStringKey(s.title), comment: "Onboarding task suggestion chip label")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)
                                    Spacer(minLength: 0)
                                }
                                .padding(.horizontal, scaled(14))
                                .padding(.vertical, scaled(12))
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: scaled(12))
                                        .fill(.white)
                                        .shadow(color: .black.opacity(0.04), radius: scaled(4), y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: scaled(12))
                                        .strokeBorder(taskTitle == String(localized: String.LocalizationValue(s.title)) ? coral.opacity(0.5) : Color(.systemGray5), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, scaled(24))

                Spacer()

                if let onContinue {
                    OnboardingPrimaryButton(
                        title: "Continue",
                        colorHex: "#8B7355",
                        isDisabled: taskTitle.trimmingCharacters(in: .whitespaces).isEmpty,
                        action: onContinue
                    )
                    .padding(.horizontal, scaled(24))
                    .padding(.bottom, scaled(32))
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { focused = true }
        }
    }
}

#Preview {
    OnboardingTaskEntryPage(taskTitle: .constant(""), taskIcon: .constant("envelope.fill"))
}
