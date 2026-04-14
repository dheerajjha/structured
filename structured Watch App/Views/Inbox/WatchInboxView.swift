import SwiftUI
import SwiftData

struct WatchInboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(
        filter: #Predicate<WatchTask> { $0.isInbox },
        sort: \WatchTask.createdAt,
        order: .reverse
    )
    private var inboxTasks: [WatchTask]

    @State private var showingNewTask = false
    @State private var editingTask: WatchTask?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if inboxTasks.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(inboxTasks, id: \.id) { task in
                            Button {
                                editingTask = task
                            } label: {
                                HStack(spacing: 8) {
                                    WatchTaskIconView(
                                        iconName: task.iconName,
                                        colorHex: task.colorHex,
                                        size: 24
                                    )

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(task.title)
                                            .font(.footnote.weight(.semibold))
                                            .lineLimit(1)
                                        if !task.durationLabel.isEmpty {
                                            Text(task.durationLabel)
                                                .font(.system(size: 10))
                                                .foregroundStyle(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(hex: task.colorHex).pastel())
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    let taskId = task.id.uuidString
                                    withAnimation { modelContext.delete(task) }
                                    WatchConnectivityManager.shared.sendTaskUpdate(
                                        "delete", taskId: taskId
                                    )
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.carousel)
                }
            }

                // Floating add button
                Button { showingNewTask = true } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(hex: "#E8907E")))
                        .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 8)
                .padding(.bottom, 4)
            }
            .sheet(isPresented: $showingNewTask) {
                WatchTaskEditorView(task: nil, selectedDate: Date(), startAsInbox: true)
            }
            .sheet(item: $editingTask) { task in
                WatchTaskEditorView(task: task, selectedDate: Date())
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "tray")
                .font(.system(size: 28))
                .foregroundStyle(Color(.gray))
            Text("No tasks yet")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("Capture ideas here")
                .font(.caption2)
                .foregroundStyle(Color(.gray))

            Button { showingNewTask = true } label: {
                Label("Add Task", systemImage: "plus.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "#E8907E"))
            .padding(.top, 4)
            Spacer()
        }
    }
}
