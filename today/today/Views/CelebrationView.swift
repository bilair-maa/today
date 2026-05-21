import SwiftUI

struct CelebrationState: Identifiable {
    let id = UUID()
    let message: String
    let isAllDone: Bool
}

// Expanding rings with a motivational message. Shown briefly when a task is completed.
struct CelebrationView: View {
    let state: CelebrationState
    let colors: TodayColors
    let onDismiss: () -> Void

    // Using @SwiftUI.State to disambiguate from CelebrationState
    @SwiftUI.State private var showRings = false
    @SwiftUI.State private var showText = false

    private var ringCount: Int { state.isAllDone ? 4 : 2 }

    var body: some View {
        GeometryReader { geo in
            let size = max(geo.size.width, geo.size.height)
            ZStack {
                ForEach(0..<ringCount, id: \.self) { i in
                    Circle()
                        .stroke(
                            colors.done.opacity(showRings ? 0 : 0.2),
                            lineWidth: state.isAllDone ? 2 : 1.5
                        )
                        .frame(width: size * 0.15, height: size * 0.15)
                        .scaleEffect(showRings ? CGFloat(2.5 + Double(i) * 1.8) : 0.1)
                        .animation(
                            .easeOut(duration: state.isAllDone ? 1.6 : 1.1)
                                .delay(Double(i) * 0.12),
                            value: showRings
                        )
                }

                if !state.isAllDone {
                    Text(state.message)
                        .font(.system(size: 28, weight: .medium, design: .serif))
                        .foregroundStyle(colors.fg)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .scaleEffect(showText ? 1.0 : 0.5)
                        .opacity(showText ? 1.0 : 0)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.6)) {
                showText = true
            }
            showRings = true

            let displayTime: Double = state.isAllDone ? 2.2 : 1.4
            DispatchQueue.main.asyncAfter(deadline: .now() + displayTime) {
                withAnimation(.easeOut(duration: 0.2)) {
                    showText = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    onDismiss()
                }
            }
        }
    }
}
