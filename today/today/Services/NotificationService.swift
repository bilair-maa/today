import Foundation
import UserNotifications
import Combine

// Manages all local notifications: task expiration reminders, daily check-ins, and priority nudges.
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permissions

    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestPermission() async -> Bool {
        let currentSettings = await center.notificationSettings()
        // If the user already denied in system settings, don't prompt again
        if currentSettings.authorizationStatus == .denied {
            isAuthorized = false
            return false
        }

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Task Expiration Reminders

    // Fires at (expirationDate - reminderOffset) to give the user a heads up
    func scheduleExpirationReminder(for task: Task) {
        guard let expiration = task.expirationDate,
              let offset = task.reminderOffset,
              !task.isCompleted else { return }

        let fireDate = expiration.addingTimeInterval(-offset.timeInterval)
        guard fireDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "Task Reminder"

        if offset == .atExpiration {
            content.body = "\"\(task.title)\" is expiring now."
        } else {
            content.body = "\"\(task.title)\" expires in \(offset.label)."
        }
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "task-expiration-\(task.id.uuidString)",
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelExpirationReminder(for taskId: UUID) {
        center.removePendingNotificationRequests(
            withIdentifiers: ["task-expiration-\(taskId.uuidString)"]
        )
    }

    // MARK: - Daily Lifecycle Notifications

    // Three check-ins spaced across the user's day: morning, midday, and evening
    func scheduleDailyNotifications(dayStartHour: Int, taskCount: Int, completedCount: Int) {
        cancelDailyNotifications()

        let morningHour = dayStartHour
        let middayHour = min(dayStartHour + 8, 23)
        let eveningHour = min(dayStartHour + 14, 23)

        scheduleDailyNotification(
            id: "daily-morning",
            title: "Good morning",
            body: "What are you tackling today? Add your tasks.",
            hour: morningHour,
            minute: 0
        )

        let middayBody: String
        if taskCount == 0 {
            middayBody = "Halfway through the day — have you added your tasks?"
        } else if completedCount == taskCount {
            middayBody = "All \(taskCount) tasks done — nice work today!"
        } else {
            middayBody = "\(completedCount) of \(taskCount) done. Keep it going!"
        }
        scheduleDailyNotification(
            id: "daily-midday",
            title: "Midday Check-in",
            body: middayBody,
            hour: middayHour,
            minute: 0
        )

        let eveningBody: String
        if taskCount == 0 {
            eveningBody = "The day's winding down. Still time to get something done."
        } else {
            let remaining = taskCount - completedCount
            if remaining == 0 {
                eveningBody = "Everything's done — enjoy your evening."
            } else {
                eveningBody = "\(remaining) task\(remaining == 1 ? "" : "s") left. The day's almost over — finish strong!"
            }
        }
        scheduleDailyNotification(
            id: "daily-evening",
            title: "Evening Wrap-up",
            body: eveningBody,
            hour: eveningHour,
            minute: 0
        )
    }

    func cancelDailyNotifications() {
        center.removePendingNotificationRequests(
            withIdentifiers: ["daily-morning", "daily-midday", "daily-evening"]
        )
    }

    // MARK: - Priority Nudges

    // High priority tasks get 3 reminders throughout the day, medium gets 1
    func schedulePriorityNudges(for tasks: [Task], dayStartHour: Int) {
        cancelPriorityNudges(for: tasks)

        let highTasks = tasks.filter { $0.priority == .high && !$0.isCompleted }
        let mediumTasks = tasks.filter { $0.priority == .medium && !$0.isCompleted }

        let midHour = min(dayStartHour + 6, 23)
        let afternoonHour = min(dayStartHour + 10, 23)
        let lateHour = min(dayStartHour + 13, 23)

        for task in highTasks {
            let id = task.id.uuidString
            scheduleDailyNotification(
                id: "priority-\(id)-1",
                title: task.title,
                body: "High priority — don't forget this one.",
                hour: midHour,
                minute: 0
            )
            scheduleDailyNotification(
                id: "priority-\(id)-2",
                title: task.title,
                body: "Still incomplete — make time for this today.",
                hour: afternoonHour,
                minute: 0
            )
            scheduleDailyNotification(
                id: "priority-\(id)-3",
                title: task.title,
                body: "Last chance — this was marked high priority.",
                hour: lateHour,
                minute: 0
            )
        }

        for task in mediumTasks {
            let id = task.id.uuidString
            scheduleDailyNotification(
                id: "priority-\(id)-1",
                title: task.title,
                body: "Remember to get this done today.",
                hour: afternoonHour,
                minute: 0
            )
        }
    }

    func cancelPriorityNudges(for tasks: [Task]) {
        var ids: [String] = []
        for task in tasks {
            let id = task.id.uuidString
            ids.append(contentsOf: [
                "priority-\(id)-1",
                "priority-\(id)-2",
                "priority-\(id)-3"
            ])
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Clear All

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Helpers

    private func scheduleDailyNotification(id: String, title: String, body: String, hour: Int, minute: Int) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let now = Date()
        let calendar = Calendar.current
        guard var fireDate = calendar.nextDate(after: now, matching: components, matchingPolicy: .nextTime) else { return }

        if fireDate < now {
            fireDate = calendar.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }

        let triggerComponents = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        center.add(request)
    }
}
