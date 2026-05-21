import SwiftUI

struct LargeWidgetView: View {
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

    private var dayStartTime: String { "0:00" }
    private var dayMidTime: String { "12:00" }
    private var dayEndTime: String { "24:00" }

    // How far through the day we are, used for the progress bar at the top
    private var dayProgress: Double {
        let cal = Calendar.current
        let startHour = max(entry.dayStartHour, 0)
        let adjusted = entry.date.addingTimeInterval(-Double(startHour) * 3600)
        let startOfAdjusted = cal.startOfDay(for: adjusted)
        let start = startOfAdjusted.addingTimeInterval(Double(startHour) * 3600)
        let end = start.addingTimeInterval(24 * 3600)
        let now = entry.date
        if now <= start { return 0 }
        if now >= end { return 1 }
        return now.timeIntervalSince(start) / end.timeIntervalSince(start)
    }

    private var sortedTasks: [WidgetTask] {
        let withTime = entry.tasks.filter { $0.expirationDate != nil }
            .sorted { ($0.expirationDate ?? .distantFuture) < ($1.expirationDate ?? .distantFuture) }
        let noTime = entry.tasks.filter { $0.expirationDate == nil }
        return withTime + noTime
    }

    var body: some View {
        if entry.tasks.isEmpty {
            emptyBody
        } else {
            taskBody
        }
    }

    private var emptyBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            timelineBar
                .padding(.top, 12)

            Spacer()

            Text("No tasks yet")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(colors.fgMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
    }

    private var taskBody: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            timelineBar
                .padding(.top, 12)
            taskListSection
                .padding(.top, 10)
            Spacer(minLength: 0)
            footerSection
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(16)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dayFull)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(colors.fgMuted)
                .textCase(.uppercase)

            Text(dateString)
                .font(.system(size: 36, weight: .regular, design: .serif))
                .foregroundStyle(colors.fg)
                .padding(.top, 1)
        }
    }

    private var timelineBar: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(colors.surface)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(colors.accent)
                        .frame(width: width * dayProgress, height: 3)

                    Circle()
                        .fill(colors.fg)
                        .frame(width: 7, height: 7)
                        .offset(x: width * dayProgress - 3.5)
                }
            }
            .frame(height: 7)

            HStack {
                Text(dayStartTime)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(colors.fgFaint)

                Spacer()

                Text(dayMidTime)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(colors.fgFaint)

                Spacer()

                Text(dayEndTime)
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(colors.fgFaint)
            }
        }
    }

    private var taskListSection: some View {
        VStack(spacing: 0) {
            let tasks = Array(sortedTasks.prefix(5))
            ForEach(Array(tasks.enumerated()), id: \.element.id) { index, task in
                if index > 0 {
                    Rectangle()
                        .fill(colors.hairline)
                        .frame(height: 0.5)
                        .padding(.leading, 14)
                }

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
                .padding(.vertical, 8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var footerSection: some View {
        HStack(spacing: 8) {
            if entry.totalCount > 0 {
                ProgressCircleView(progress: entry.progress, colors: colors, size: 36)

                Text("\(entry.completedCount) / \(entry.totalCount)")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(colors.fgMuted)
            }

            Spacer()
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "H:mm"
        return formatter.string(from: date)
    }

}
