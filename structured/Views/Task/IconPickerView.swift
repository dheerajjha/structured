import SwiftUI

/// Grid of SF Symbol icons for task customization
struct IconPickerView: View {
    @Binding var selectedIcon: String
    @Environment(\.dismiss) private var dismiss

    static let icons: [String] = [
        // General
        "star.fill", "heart.fill", "flag.fill", "bookmark.fill",
        "bell.fill", "tag.fill", "bolt.fill", "flame.fill",

        // Work & Productivity
        "briefcase.fill", "doc.fill", "folder.fill", "tray.fill",
        "paperplane.fill", "envelope.fill", "phone.fill", "desktopcomputer",

        // Education
        "book.fill", "graduationcap.fill", "pencil", "text.book.closed.fill",
        "lightbulb.fill", "brain.head.profile", "puzzlepiece.fill", "chart.bar.fill",

        // Health & Fitness
        "figure.run", "figure.yoga", "figure.walk", "dumbbell.fill",
        "heart.text.square.fill", "cross.case.fill", "pills.fill", "bed.double.fill",

        // Food & Drink
        "cup.and.saucer.fill", "fork.knife", "carrot.fill", "leaf.fill",
        "drop.fill", "takeoutbag.and.cup.and.straw.fill",

        // Transportation
        "car.fill", "bicycle", "bus.fill", "airplane",
        "tram.fill", "figure.walk",

        // Home & Life
        "house.fill", "washer.fill", "cart.fill", "gift.fill",
        "wrench.fill", "paintbrush.fill", "scissors", "camera.fill",

        // Social & Entertainment
        "person.fill", "person.2.fill", "music.note", "gamecontroller.fill",
        "tv.fill", "theatermasks.fill", "party.popper.fill", "globe",

        // Nature & Weather
        "sun.max.fill", "moon.fill", "cloud.fill", "snowflake",
        "mountain.2.fill", "tree.fill", "pawprint.fill",

        // Misc
        "clock.fill", "calendar", "mappin.and.ellipse", "location.fill",
        "wifi", "battery.100", "hand.thumbsup.fill", "sparkles",
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: scaled(12)), count: 6),
                    spacing: scaled(12)
                ) {
                    ForEach(Self.icons, id: \.self) { icon in
                        Button {
                            selectedIcon = icon
                            dismiss()
                        } label: {
                            Image(systemName: icon)
                                .font(.title3)
                                .frame(width: scaled(48), height: scaled(48))
                                .background(
                                    RoundedRectangle(cornerRadius: scaled(10))
                                        .fill(selectedIcon == icon ? Color.accentColor.opacity(0.15) : Color(.systemGray6))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: scaled(10))
                                        .strokeBorder(selectedIcon == icon ? Color.accentColor : .clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
