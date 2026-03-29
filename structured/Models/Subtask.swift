import Foundation
import SwiftData

@Model
class Subtask {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var order: Int = 0
    var task: StructuredTask?

    init(title: String, isCompleted: Bool = false, order: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = isCompleted
        self.order = order
    }
}
