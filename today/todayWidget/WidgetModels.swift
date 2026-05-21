import Foundation
import WidgetKit

// Lightweight copies of the app's models for the widget extension.
// The widget can't import the main app target, so these mirror just the fields it needs.

struct WidgetCategory: Codable, Hashable {
    let id: UUID
    var name: String
    var isDefault: Bool
}

struct WidgetTask: Codable, Identifiable {
    let id: UUID
    var title: String
    var note: String?
    var expirationDate: Date?
    var category: WidgetCategory
    var priority: Int
    var isCompleted: Bool
}

struct TaskEntry: TimelineEntry {
    let date: Date
    let tasks: [WidgetTask]
    let completedCount: Int
    let totalCount: Int
    let palette: String
    let dayStartHour: Int

    var nextIncompleteTask: WidgetTask? {
        tasks.first { !$0.isCompleted }
    }

    var tasksWithTime: [WidgetTask] {
        tasks.filter { $0.expirationDate != nil }
            .sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
    }

    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }

    static let placeholder = TaskEntry(
        date: Date(),
        tasks: [
            WidgetTask(id: UUID(), title: "Morning walk", expirationDate: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()), category: WidgetCategory(id: UUID(), name: "self", isDefault: true), priority: 1, isCompleted: true),
            WidgetTask(id: UUID(), title: "Design review notes", expirationDate: Calendar.current.date(bySettingHour: 11, minute: 0, second: 0, of: Date()), category: WidgetCategory(id: UUID(), name: "work", isDefault: true), priority: 1, isCompleted: true),
            WidgetTask(id: UUID(), title: "Reply to Maya", expirationDate: nil, category: WidgetCategory(id: UUID(), name: "home", isDefault: true), priority: 0, isCompleted: false),
            WidgetTask(id: UUID(), title: "Pick up prescription", expirationDate: Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()), category: WidgetCategory(id: UUID(), name: "errand", isDefault: true), priority: 1, isCompleted: false),
            WidgetTask(id: UUID(), title: "Yoga", expirationDate: Calendar.current.date(bySettingHour: 18, minute: 30, second: 0, of: Date()), category: WidgetCategory(id: UUID(), name: "self", isDefault: true), priority: 0, isCompleted: false),
        ],
        completedCount: 2,
        totalCount: 5,
        palette: "warm",
        dayStartHour: 0
    )
}
