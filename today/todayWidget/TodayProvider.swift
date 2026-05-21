import WidgetKit
import Foundation

// Reads tasks from the shared UserDefaults container and builds timeline entries for the widget.
struct TodayProvider: TimelineProvider {
    private static let suiteName = "group.com.shahana.today"

    func placeholder(in context: Context) -> TaskEntry {
        TaskEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TaskEntry) -> Void) {
        if context.isPreview {
            completion(TaskEntry.placeholder)
        } else {
            completion(readEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TaskEntry>) -> Void) {
        let base = readEntry()
        var entries: [TaskEntry] = []

        for minuteOffset in stride(from: 0, through: 45, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: Date()) ?? Date()
            let entry = TaskEntry(
                date: entryDate,
                tasks: base.tasks,
                completedCount: base.completedCount,
                totalCount: base.totalCount,
                palette: base.palette,
                dayStartHour: base.dayStartHour
            )
            entries.append(entry)
        }

        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: entries, policy: .after(nextUpdate))
        completion(timeline)
    }

    private func readEntry() -> TaskEntry {
        let defaults = UserDefaults(suiteName: Self.suiteName)

        let tasks: [WidgetTask] = {
            guard let data = defaults?.data(forKey: "savedTasks"),
                  let decoded = try? JSONDecoder().decode([WidgetTask].self, from: data) else {
                return []
            }
            return decoded
        }()

        let palette = defaults?.string(forKey: "themePalette") ?? "warm"
        let dayStartHour = defaults?.integer(forKey: "dayStartHour") ?? 0

        let completedCount = tasks.filter(\.isCompleted).count

        return TaskEntry(
            date: Date(),
            tasks: tasks,
            completedCount: completedCount,
            totalCount: tasks.count,
            palette: palette,
            dayStartHour: dayStartHour
        )
    }
}
