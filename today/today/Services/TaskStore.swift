//
//  TaskStore.swift
//  today
//

import Foundation
import Combine
import WidgetKit

// Persists tasks and categories to UserDefaults, syncs task data to the widget's shared container.
class TaskStore: ObservableObject {
    private static let tasksKey = "savedTasks"
    private static let categoriesKey = "savedCategories"
    private static let lastDateKey = "lastActiveDate"
    private static let suiteName = "group.com.shahana.today"

    @Published var tasks: [Task]
    @Published var categories: [Category]

    init() {
        self.tasks = TaskStore.loadTasks()
        self.categories = TaskStore.loadCategories()
        if UserDefaults.standard.data(forKey: TaskStore.categoriesKey) == nil {
            saveCategories()
        }
    }

    // Clears tasks when the calendar day rolls over
    func validateDay(dayStartHour: Int = 0) {
        let today = todaysDateString(dayStartHour: dayStartHour)

        guard let lastDate = UserDefaults.standard.string(forKey: TaskStore.lastDateKey) else {
            UserDefaults.standard.set(today, forKey: TaskStore.lastDateKey)
            return
        }

        guard lastDate != today else { return }

        UserDefaults.standard.set(today, forKey: TaskStore.lastDateKey)

        guard !tasks.isEmpty else { return }

        tasks = []
        saveTasks()
    }

    // New tasks go to the top of the list
    func addTask(_ task: Task) {
        var newTask = task
        for i in tasks.indices {
            tasks[i].sortOrder += 1
        }
        newTask.sortOrder = 0
        tasks.append(newTask)
        saveTasks()
    }

    func removeTask(_ task: Task) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }

    func toggleCompleted(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
        saveTasks()
    }

    func updateTask(_ task: Task) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
        saveTasks()
    }

    // Preserves existing sortOrder values but reassigns them to match the new visual order
    func reorderTasks(_ orderedIds: [UUID]) {
        let existingSortOrders = orderedIds.compactMap { id in
            tasks.firstIndex(where: { $0.id == id }).map { tasks[$0].sortOrder }
        }.sorted()
        for (index, id) in orderedIds.enumerated() {
            if let taskIndex = tasks.firstIndex(where: { $0.id == id }),
               index < existingSortOrders.count {
                tasks[taskIndex].sortOrder = existingSortOrders[index]
            }
        }
        saveTasks()
    }

    func addCategory(_ category: Category) {
        categories.append(category)
        saveCategories()
    }

    func removeCategory(_ category: Category) {
        guard !category.isDefault else { return }
        categories.removeAll { $0.id == category.id }
        saveCategories()
    }

    // Also updates the category name on any tasks that reference it
    func renameCategory(_ category: Category, to newName: String) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        categories[index].name = newName
        for i in tasks.indices where tasks[i].category.id == category.id {
            tasks[i].category.name = newName
        }
        saveCategories()
        saveTasks()
    }

    // MARK: - Persistence

    private func saveTasks() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: TaskStore.tasksKey)
            UserDefaults(suiteName: TaskStore.suiteName)?.set(data, forKey: TaskStore.tasksKey)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func saveCategories() {
        if let data = try? JSONEncoder().encode(categories) {
            UserDefaults.standard.set(data, forKey: TaskStore.categoriesKey)
        }
    }

    private static func loadTasks() -> [Task] {
        guard let data = UserDefaults.standard.data(forKey: tasksKey),
              var tasks = try? JSONDecoder().decode([Task].self, from: data) else {
            return []
        }
        // One-time migration for tasks saved before sortOrder existed
        let needsMigration = tasks.count > 1 && tasks.allSatisfy({ $0.sortOrder == 0 })
        if needsMigration {
            for i in tasks.indices {
                tasks[i].sortOrder = i
            }
        }
        return tasks
    }

    private static func loadCategories() -> [Category] {
        guard let data = UserDefaults.standard.data(forKey: categoriesKey),
              let categories = try? JSONDecoder().decode([Category].self, from: data) else {
            return Category.defaultCategories
        }
        return categories
    }
}
