import SwiftUI

struct MediumWidgetView: View {
    let entry: TaskEntry
    let colors: WidgetColors

    private var dayFull: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }

    private var displayTasks: [WidgetTask] {
        let incomplete = entry.tasks.filter { !$0.isCompleted }
        let completed = entry.tasks.filter { $0.isCompleted }
        return Array((incomplete + completed).prefix(3))
    }

    var body: some View {
        if displayTasks.isEmpty {
            emptyBody
        } else {
            taskBody
        }
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dayFull)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(colors.fgMuted)
                .textCase(.uppercase)

            Text(dateString)
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(colors.fg)
                .padding(.top, 1)

            Spacer()

            Text("No tasks yet")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(colors.fgMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
    }

    private var taskBody: some View {
        HStack(alignment: .top, spacing: 16) {
            leftColumn
            rightColumn
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(16)
    }

    private var leftColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dayFull)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(colors.fgMuted)
                .textCase(.uppercase)

            Text(dateString)
                .font(.system(size: 28, weight: .regular, design: .serif))
                .foregroundStyle(colors.fg)
                .padding(.top, 1)

            Spacer()

            if entry.totalCount > 0 {
                HStack(spacing: 8) {
                    ProgressCircleView(progress: entry.progress, colors: colors, size: 26)

                    Text("\(entry.completedCount) / \(entry.totalCount)")
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundStyle(colors.fgMuted)
                }
            }
        }
        .frame(width: 110, alignment: .leading)
    }

    private var rightColumn: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(displayTasks.enumerated()), id: \.element.id) { index, task in
                if index > 0 {
                    Rectangle()
                        .fill(colors.hairline)
                        .frame(height: 0.5)
                        .padding(.leading, 14)
                }

                taskRow(task)
            }
            Spacer(minLength: 0)
        }
    }

    private func taskRow(_ task: WidgetTask) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(colors.categoryColor(for: task.category.name))
                .frame(width: 6, height: 6)

            Text(task.title)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(task.isCompleted ? colors.fgFaint : colors.fg)
                .strikethrough(task.isCompleted, color: colors.fgFaint)
                .lineLimit(1)

            Spacer(minLength: 0)

            if let date = task.expirationDate {
                Text(timeString(from: date))
                    .font(.system(size: 10, weight: .regular, design: .monospaced))
                    .foregroundStyle(colors.fgMuted)
            }
        }
        .padding(.vertical, 10)
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }
}
