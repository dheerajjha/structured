import Foundation
import WatchConnectivity
import SwiftData

class WatchConnectivityManager: NSObject, @unchecked Sendable {
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

    /// Send a full task to iPhone for creation
    func sendNewTask(_ task: WatchTask) {
        send(action: "create", for: task)
    }

    /// Send a full edited task payload to iPhone so it can overwrite its copy.
    func sendEditedTask(_ task: WatchTask) {
        send(action: "update", for: task)
    }

    /// Push updated anchor times (from Watch Settings) to the iPhone so the
    /// iPhone's DailyAnchorManager stays in sync with what the user set on the watch.
    func sendAnchorUpdate(wakeHour: Int, wakeMinute: Int, bedHour: Int, bedMinute: Int) {
        let payload: [String: Any] = [
            "action": "anchor_update",
            "taskId": "anchor",
            "wakeHour": wakeHour,
            "wakeMinute": wakeMinute,
            "bedHour": bedHour,
            "bedMinute": bedMinute,
            "timestamp": Date().timeIntervalSince1970
        ]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }

    private func send(action: String, for task: WatchTask) {
        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        var payload: [String: Any] = [
            "action": action,
            "taskId": task.id.uuidString,
            "title": task.title,
            "duration": task.duration,
            "date": dateFmt.string(from: task.date),
            "colorHex": task.colorHex,
            "iconName": task.iconName,
            "isCompleted": task.isCompleted,
            "isAllDay": task.isAllDay,
            "isInbox": task.isInbox,
            "order": task.order,
            "notes": task.notes,
            "modifiedAt": task.modifiedAt.timeIntervalSince1970,
            "timestamp": Date().timeIntervalSince1970
        ]
        if let startTime = task.startTime {
            payload["startTime"] = isoFmt.string(from: startTime)
        }

        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil)
        } else {
            WCSession.default.transferUserInfo(payload)
        }
    }
}

// MARK: - WCSessionDelegate

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        #if DEBUG
        if let error {
            print("[WC Watch] Activation error: \(error.localizedDescription)")
        }
        #endif
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let tasksData = applicationContext["tasks"] as? [[String: Any]] else { return }
        let anchors = applicationContext["anchors"] as? [String: Any]
        Task { @MainActor in
            await syncTasks(from: tasksData, anchors: anchors)
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let tasksData = message["tasks"] as? [[String: Any]] {
            let anchors = message["anchors"] as? [String: Any]
            Task { @MainActor in
                await syncTasks(from: tasksData, anchors: anchors)
            }
        }
    }

    // MARK: - Sync Tasks from iPhone

    @MainActor
    private func syncTasks(from tasksData: [[String: Any]], anchors: [String: Any]?) async {
        guard let container = modelContainer else { return }
        let context = container.mainContext

        let isoFmt = ISO8601DateFormatter()
        isoFmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let dateFmt = DateFormatter()
        dateFmt.dateFormat = "yyyy-MM-dd"

        var knownIds: Set<UUID> = []

        for taskDict in tasksData {
            guard let idString = taskDict["id"] as? String,
                  let id = UUID(uuidString: idString),
                  let title = taskDict["title"] as? String else { continue }
            knownIds.insert(id)

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

        // Delete any watch-side tasks that are no longer on the iPhone, except
        // tasks the watch recently created locally whose sync to the phone may
        // still be in-flight (created in the last 60 seconds).
        //
        // Anchors are a special case — they get re-created locally by
        // `WatchAnchorManager` when the watch boots without the iPhone. Once
        // the iPhone pushes its authoritative anchor tasks, drop any local
        // anchor duplicates for the same day + type so we don't render two
        // "Rise and Shine" rows.
        if !knownIds.isEmpty, let allLocal = try? context.fetch(FetchDescriptor<WatchTask>()) {
            let cutoff = Date().addingTimeInterval(-60)

            // Build a set of (day, anchorType) pairs the iPhone owns.
            var iPhoneAnchorKeys: Set<String> = []
            for t in allLocal where knownIds.contains(t.id) {
                if let type = t.anchorType, t.isProtected {
                    iPhoneAnchorKeys.insert(anchorKey(day: t.date, type: type))
                }
            }

            for local in allLocal where !knownIds.contains(local.id) {
                // If this is a local anchor and the iPhone already has one for
                // the same day + type, it's safe to drop immediately — the
                // iPhone copy is authoritative.
                if local.isProtected, let type = local.anchorType,
                   iPhoneAnchorKeys.contains(anchorKey(day: local.date, type: type)) {
                    context.delete(local)
                    continue
                }
                guard local.createdAt < cutoff else { continue }
                context.delete(local)
            }
        }

        // Keep @AppStorage-backed anchor preferences in sync with the iPhone.
        if let anchors {
            let defaults = UserDefaults.standard
            if let v = anchors["wakeHour"]   as? Int { defaults.set(v, forKey: "anchor_wake_hour") }
            if let v = anchors["wakeMinute"] as? Int { defaults.set(v, forKey: "anchor_wake_minute") }
            if let v = anchors["bedHour"]    as? Int { defaults.set(v, forKey: "anchor_bed_hour") }
            if let v = anchors["bedMinute"]  as? Int { defaults.set(v, forKey: "anchor_bed_minute") }
        }

        try? context.save()
    }

    /// Composite key used to match anchors across sources by day + type.
    private nonisolated func anchorKey(day: Date, type: String) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        return "\(fmt.string(from: day))|\(type)"
    }
}
