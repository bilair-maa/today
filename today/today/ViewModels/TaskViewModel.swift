//
//  TaskViewModel.swift
//  today
//

import Foundation
import Combine

// Sits between the views and TaskStore. Handles input validation and task operations.
@MainActor
class TaskViewModel: ObservableObject {
    private let store: TaskStore
    private var cancellable: AnyCancellable?

    var tasks: [Task] { store.tasks }
    var categories: [Category] { store.categories }

    // Incomplete tasks first, then sorted by the user's manual ordering
    var sortedTasks: [Task] {
        store.tasks.sorted { a, b in
            if a.isCompleted != b.isCompleted {
                return !a.isCompleted
            }
            return a.sortOrder < b.sortOrder
        }
    }

    init(store: TaskStore? = nil) {
        self.store = store ?? TaskStore()
        cancellable = self.store.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
    }

    func onAppLaunch(dayStartHour: Int = 0) {
        store.validateDay(dayStartHour: dayStartHour)
    }

    // Validates input before creating a task. Returns false if the input is bad.
    func addTask(title: String, note: String?, expirationDate: Date?, reminderOffset: ReminderOffset?, category: Category, priority: Priority) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 280 else { return false }

        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = (trimmedNote?.isEmpty == true) ? nil : trimmedNote
        if let cleanNote, cleanNote.count > 500 { return false }

        let task = Task(
            title: trimmedTitle,
            note: cleanNote,
            expirationDate: expirationDate,
            reminderOffset: reminderOffset,
            category: category,
            priority: priority
        )

        store.addTask(task)
        return true
    }

    func removeTask(_ task: Task) {
        store.removeTask(task)
    }

    func updateTask(_ task: Task, title: String, note: String?, expirationDate: Date?, reminderOffset: ReminderOffset?, category: Category, priority: Priority) -> Bool {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty, trimmedTitle.count <= 280 else { return false }

        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanNote = (trimmedNote?.isEmpty == true) ? nil : trimmedNote
        if let cleanNote, cleanNote.count > 500 { return false }

        var updated = task
        updated.title = trimmedTitle
        updated.note = cleanNote
        updated.expirationDate = expirationDate
        updated.reminderOffset = reminderOffset
        updated.category = category
        updated.priority = priority

        store.updateTask(updated)
        return true
    }

    func addCategory(name: String) -> Category? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let category = Category(name: trimmed)
        store.addCategory(category)
        return category
    }

    func removeCategory(_ category: Category) {
        guard !category.isDefault else { return }
        store.removeCategory(category)
    }

    // Prevents duplicate category names (case insensitive)
    func renameCategory(_ category: Category, to newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let exists = categories.contains { $0.id != category.id && $0.name.lowercased() == trimmed.lowercased() }
        guard !exists else { return false }
        store.renameCategory(category, to: trimmed)
        return true
    }

    func toggleCompleted(_ task: Task) {
        store.toggleCompleted(task)
    }

    func reorderTasks(_ orderedIds: [UUID]) {
        store.reorderTasks(orderedIds)
    }

    func enableNotifications() async -> Bool {
        let granted = await NotificationService.shared.requestPermission()
        return granted
    }

    func disableNotifications() {
        NotificationService.shared.cancelAllNotifications()
    }

    // Re-schedules all notifications based on current task state
    func refreshNotifications(dayStartHour: Int) {
        let service = NotificationService.shared
        for task in tasks {
            service.cancelExpirationReminder(for: task.id)
            if !task.isCompleted {
                service.scheduleExpirationReminder(for: task)
            }
        }
        let completedCount = tasks.filter(\.isCompleted).count
        service.scheduleDailyNotifications(
            dayStartHour: dayStartHour,
            taskCount: tasks.count,
            completedCount: completedCount
        )
        service.schedulePriorityNudges(for: tasks, dayStartHour: dayStartHour)
    }
}
