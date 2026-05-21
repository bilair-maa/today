import SwiftUI

struct SmallWidgetView: View {
    let entry: TaskEntry
    let colors: WidgetColors

    private var dayAbbrev: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: entry.date)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: entry.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(dayAbbrev)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(colors.fgMuted)
                .textCase(.uppercase)

            Text(dateString)
                .font(.system(size: 30, weight: .regular, design: .serif))
                .foregroundStyle(colors.fg)
                .padding(.top, 1)

            Spacer()

            if entry.totalCount > 0 {
                HStack(spacing: 8) {
                    ProgressCircleView(progress: entry.progress, colors: colors, size: 32)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(entry.completedCount) / \(entry.totalCount)")
                            .font(.system(size: 18, weight: .regular, design: .serif))
                            .foregroundStyle(colors.fg)
                        Text("done")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(colors.fgMuted)
                            .textCase(.uppercase)
                    }
                }

                Spacer()

                if let next = entry.nextIncompleteTask {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("up next")
                            .font(.system(size: 9, weight: .regular, design: .monospaced))
                            .foregroundStyle(colors.fgFaint)
                            .textCase(.uppercase)

                        Text(next.title)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(colors.fg)
                            .lineLimit(1)
                    }
                }
            } else {
                Spacer()
                Text("No tasks yet")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(colors.fgMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }
}
