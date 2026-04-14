import Foundation
import WatchConnectivity
import SwiftData

extension Notification.Name {
    static let watchSyncNeeded = Notification.Name("watchSyncNeeded")
}

class WatchSyncManager: NSObject, @unchecked Sendable {
    static let shared = WatchSyncManager()
    var modelContainer: ModelContainer?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send all tasks to Watch

    func syncAllTasks(context: ModelContext) {
        guard WCSession.default.activationState == .activated else { return }

        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        guard let tasks = try? context.fetch(FetchDescriptor<StructuredTask>()) else { return }

        let tasksPayload: [[String: Any]] = tasks.map { task in
            var dict: [String: Any] = [
                "id": task.id.uuidString,
                "title": task.title,
                "duration": task.duration,
                "date": dateFmt.string(from: task.date),
                "colorHex": task.colorHex,
                "iconName": task.iconName,
                "isCompleted": task.isCompleted,
                "isAllDay": task.isAllDay,
                "isInbox": task.isInbox,
                "order": task.order,
                "isProtected": task.isProtected,
                "notes": task.notes,
                "modifiedAt": task.createdAt.timeIntervalSince1970,
            ]
            if let anchorType = task.anchorType {
                dict["anchorType"] = anchorType
            }
            if let startTime = task.startTime {
                dict["startTime"] = isoFmt.string(from: startTime)
            }
            return dict
        }

        let payload: [String: Any] = ["tasks": tasksPayload]

        do {
            try WCSession.default.updateApplicationContext(payload)
        } catch {
            print("[WC iOS] Failed to update application context: \(error)")
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchSyncManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[WC iOS] Activation error: \(error.localizedDescription)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }

    // MARK: - Receive from Watch

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        guard let action = message["action"] as? String,
              let taskId = message["taskId"] as? String else { return }

        Task { @MainActor in
            await handleWatchAction(action: action, taskId: taskId, payload: message)
        }
    }

    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let action = userInfo["action"] as? String,
              let taskId = userInfo["taskId"] as? String else { return }

        Task { @MainActor in
            await handleWatchAction(action: action, taskId: taskId, payload: userInfo)
        }
    }

    @MainActor
    private func handleWatchAction(action: String, taskId: String, payload: [String: Any]) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext
        guard let id = UUID(uuidString: taskId) else { return }

        // Handle task creation from watch
        if action == "create" {
            // Check if already exists
            let predicate = #Predicate<StructuredTask> { $0.id == id }
            if let existing = try? context.fetch(FetchDescriptor(predicate: predicate)), !existing.isEmpty {
                return // Already synced
            }

            let title = payload["title"] as? String ?? ""
            let duration = payload["duration"] as? TimeInterval ?? 1800
            let colorHex = payload["colorHex"] as? String ?? "#FF6B6B"
            let iconName = payload["iconName"] as? String ?? "checklist"
            let isCompleted = payload["isCompleted"] as? Bool ?? false
            let isAllDay = payload["isAllDay"] as? Bool ?? false
            let isInbox = payload["isInbox"] as? Bool ?? false
            let order = payload["order"] as? Int ?? 0
            let notes = payload["notes"] as? String ?? ""

            let dateFmt = DateFormatter()
            dateFmt.dateFormat = "yyyy-MM-dd"
            let date = (payload["date"] as? String).flatMap { dateFmt.date(from: $0) } ?? Date().startOfDay

            let isoFmt = ISO8601DateFormatter()
            isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let startTime = (payload["startTime"] as? String).flatMap { isoFmt.date(from: $0) }

            let newTask = StructuredTask(
                title: title,
                startTime: startTime,
                duration: duration,
                date: date,
                colorHex: colorHex,
                iconName: iconName,
                isCompleted: isCompleted,
                isAllDay: isAllDay,
                isInbox: isInbox,
                order: order
            )
            newTask.notes = notes
            newTask.id = id
            context.insert(newTask)

            try? context.save()
            NotificationCenter.default.post(name: .watchSyncNeeded, object: nil)
            return
        }

        // Handle updates to existing tasks
        let predicate = #Predicate<StructuredTask> { $0.id == id }
        guard let tasks = try? context.fetch(FetchDescriptor(predicate: predicate)),
              let task = tasks.first else { return }

        switch action {
        case "complete":
            task.isCompleted = true
        case "uncomplete":
            task.isCompleted = false
        case "unschedule":
            task.isInbox = true
            task.startTime = nil
        case "move":
            if let hour = payload["hour"] as? Int, let minute = payload["minute"] as? Int {
                let base = task.startTime ?? task.date
                task.startTime = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: base)
            }
        case "delete":
            context.delete(task)
        default:
            break
        }

        try? context.save()
        NotificationCenter.default.post(name: .watchSyncNeeded, object: nil)
    }
}
