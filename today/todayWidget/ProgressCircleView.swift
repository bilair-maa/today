import SwiftUI

struct ProgressCircleView: View {
    let progress: Double
    let colors: WidgetColors
    let size: CGFloat

    private var lineWidth: CGFloat { size > 30 ? 3 : 2.4 }

    var body: some View {
        ZStack {
            Circle()
                .stroke(colors.fg.opacity(0.06), lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(colors.accent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}
