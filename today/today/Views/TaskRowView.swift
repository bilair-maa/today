import SwiftUI

// A single task row in the main list. Shows title, category, priority dot, and expiration time.
struct TaskRowView: View {
    let task: Task
    let onToggle: () -> Void
    let onTap: () -> Void

    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme
    @State private var checkScale: CGFloat = 1.0

    private var colors: TodayColors {
        .colors(for: settings.palette, scheme: settings.effectiveColorScheme(from: colorScheme))
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Button {
                triggerCheckAnimation()
                onToggle()
            } label: {
                ZStack {
                    if task.isCompleted {
                        Circle()
                            .fill(colors.done)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(colors.bg)
                    } else {
                        Circle()
                            .stroke(colors.fgFaint, lineWidth: 1.5)
                            .frame(width: 22, height: 22)
                    }
                }
                .scaleEffect(checkScale)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.system(size: 17, weight: .medium, design: .serif))
                        .strikethrough(task.isCompleted, color: colors.fgMuted)
                        .foregroundStyle(task.isCompleted ? colors.fgMuted : colors.fg)
                        .lineLimit(2)

                    if let note = task.note, !note.isEmpty {
                        Text(note.replacingOccurrences(of: "\n", with: " "))
                            .font(.system(size: 15))
                            .foregroundStyle(colors.fgMuted)
                            .lineLimit(1)
                    }

                    HStack(spacing: 6) {
                        if let date = task.expirationDate {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 12))
                                Text(timeString(from: date))
                                    .font(.system(size: 13, design: .monospaced))
                            }
                        }
                        Text(task.category.name.uppercased())
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                    }
                    .foregroundStyle(colors.fgMuted)
                }

                Spacer()

                Circle()
                    .fill(task.priority.color)
                    .frame(width: 8, height: 8)
                    .padding(.top, 8)
            }
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .opacity(task.isCompleted ? 0.55 : 1.0)
    }

    // Quick bounce effect on the checkbox when toggling
    private func triggerCheckAnimation() {
        withAnimation(.easeOut(duration: 0.15)) {
            checkScale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.15)) {
                checkScale = 1.08
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            withAnimation(.easeOut(duration: 0.08)) {
                checkScale = 1.0
            }
        }
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}
