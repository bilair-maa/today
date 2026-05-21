import SwiftUI

// Brief animated overlay shown once per day when the user opens the app.
// Fades in, holds for a couple seconds, then fades out.
struct NewDayWelcomeView: View {
    let colors: TodayColors
    let onDismiss: () -> Void

    @State private var textOpacity: Double = 0
    @State private var textOffset: CGFloat = 24
    @State private var lineWidth: CGFloat = 0
    @State private var subtitleOpacity: Double = 0
    @State private var subtitleOffset: CGFloat = 16
    @State private var bgOpacity: Double = 1

    var body: some View {
        ZStack {
            colors.bg.ignoresSafeArea()
                .opacity(bgOpacity)

            VStack(spacing: 20) {
                Text("WELCOME TO")
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(colors.fgMuted)

                Rectangle()
                    .fill(colors.fgFaint)
                    .frame(width: lineWidth, height: 1)

                Text("a new day.")
                    .font(.system(size: 48, weight: .regular, design: .serif))
                    .tracking(-0.5)
                    .foregroundStyle(colors.fg)
                    .opacity(subtitleOpacity)
                    .offset(y: subtitleOffset)
            }
            .opacity(textOpacity)
            .offset(y: textOffset)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.7)) {
                textOpacity = 1
                textOffset = 0
            }

            withAnimation(.easeOut(duration: 0.9).delay(0.3)) {
                lineWidth = 56
            }

            withAnimation(.easeOut(duration: 0.7).delay(0.4)) {
                subtitleOpacity = 1
                subtitleOffset = 0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
                withAnimation(.easeIn(duration: 0.5)) {
                    textOpacity = 0
                    textOffset = -12
                    subtitleOpacity = 0
                    bgOpacity = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
                    onDismiss()
                }
            }
        }
    }
}
