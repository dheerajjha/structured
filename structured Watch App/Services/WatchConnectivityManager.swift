import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    var modelContainer: ModelContainer?

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    // MARK: - Send to iPhone

    func sendTaskUpdate(_ action: String, taskId: String, payload: [String: Any] = [:]) {
        var message: [String: Any] = [
            "action": action,
            "taskId": taskId,
            "timestamp": Date().timeIntervalSince1970
        ]
        message.merge(payload) { _, new in new }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(message, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(message)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error {
            print("[WC Watch] Activation error: \(error.localizedDescription)")
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let tasksData = applicationContext["tasks"] as? [[String: Any]] else { return }
        Task { @MainActor in
            await syncTasks(from: tasksData)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let tasksData = message["tasks"] as? [[String: Any]] {
            Task { @MainActor in
                await syncTasks(from: tasksData)
            }
        }
    }

    // MARK: - Sync Tasks from iPhone

    @MainActor
    private func syncTasks(from tasksData: [[String: Any]]) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        for taskDict in tasksData {
            guard let idString = taskDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = taskDict["title"] as? String else { continue }

            // Try to find existing task
            let predicate = #Predicate<WatchTask> { $0.id == id }
            let existing = try? context.fetch(FetchDescriptor(predicate: predicate))

            let task = existing?.first ?? WatchTask(title: title)
            if existing?.first == nil {
                task.id = id
                context.insert(task)
            }

            task.title = title
            task.duration = taskDict["duration"] as? TimeInterval ?? 1800
            task.colorHex = taskDict["colorHex"] as? String ?? "#FF6B6B"
            task.iconName = taskDict["iconName"] as? String ?? "star.fill"
            task.isCompleted = taskDict["isCompleted"] as? Bool ?? false
            task.isAllDay = taskDict["isAllDay"] as? Bool ?? false
            task.isInbox = taskDict["isInbox"] as? Bool ?? false
            task.order = taskDict["order"] as? Int ?? 0
            task.isProtected = taskDict["isProtected"] as? Bool ?? false
            task.anchorType = taskDict["anchorType"] as? String
            task.notes = taskDict["notes"] as? String ?? ""

            if let dateStr = taskDict["date"] as? String {
                task.date = dateFmt.date(from: dateStr) ?? Date().startOfDay
            }
            if let startStr = taskDict["startTime"] as? String {
                task.startTime = isoFmt.date(from: startStr)
            } else {
                task.startTime = nil
            }

            if let timestamp = taskDict["modifiedAt"] as? TimeInterval {
                task.modifiedAt = Date(timeIntervalSince1970: timestamp)
            }
        }

        try? context.save()
    }
}
