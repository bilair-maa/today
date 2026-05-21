import SwiftUI

// Five-step onboarding shown on first launch. The last step asks for notification permission.
struct OnboardingView: View {
    let colors: TodayColors
    var keepBackground: Bool = false
    let onComplete: () -> Void

    @EnvironmentObject private var settings: AppSettings

    @State private var currentStep = 0
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 30
    @State private var bgOpacity: Double = 1
    @State private var notificationsGranted: Bool? = nil

    private let steps: [(title: String, body: String, icon: String)] = [
        (
            "welcome to today",
            "let's take it one day at a time.",
            "sun.horizon"
        ),
        (
            "add your tasks",
            "tap the button at the bottom to add what you want to get done.",
            "plus.circle"
        ),
        (
            "set your priority",
            "higher priority tasks will send you more notifications throughout the day to keep them top of mind.",
            "bell.badge"
        ),
        (
            "a fresh start",
            "your tasks reset each day. focus on what matters today.",
            "arrow.clockwise"
        ),
        (
            "stay on track",
            "enable notifications to get morning, midday, and evening check-ins, plus reminders for tasks with deadlines.",
            "bell"
        )
    ]

    private var isLastStep: Bool { currentStep == steps.count - 1 }

    var body: some View {
        ZStack {
            colors.bg.ignoresSafeArea()
                .opacity(bgOpacity)

            VStack(spacing: 0) {
                Spacer()

                stepIndicator
                    .padding(.bottom, 40)

                Image(systemName: steps[currentStep].icon)
                    .font(.system(size: 48, weight: .thin))
                    .foregroundStyle(colors.fgMuted)
                    .frame(height: 60)
                    .padding(.bottom, 32)

                Text(steps[currentStep].title)
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .tracking(-0.3)
                    .foregroundStyle(colors.fg)
                    .multilineTextAlignment(.center)

                Text(steps[currentStep].body)
                    .font(.system(size: 17))
                    .foregroundStyle(colors.fgMuted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .frame(maxWidth: 300)
                    .padding(.top, 16)

                if isLastStep {
                    notificationPrompt
                        .padding(.top, 32)
                }

                Spacer()

                bottomControls
                    .padding(.horizontal, 24)
                    .padding(.bottom, 56)
            }
            .opacity(contentOpacity)
            .offset(y: contentOffset)
        }
        .onAppear {
            animateIn()
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<steps.count, id: \.self) { index in
                Capsule()
                    .fill(index == currentStep ? colors.fg : colors.fgFaint.opacity(0.4))
                    .frame(width: index == currentStep ? 24 : 8, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
    }

    // MARK: - Notification Prompt

    private var notificationPrompt: some View {
        VStack(spacing: 12) {
            if let granted = notificationsGranted {
                HStack(spacing: 8) {
                    Image(systemName: granted ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 18))
                    Text(granted ? "notifications enabled" : "you can enable notifications later in settings")
                        .font(.system(size: 15))
                }
                .foregroundStyle(granted ? colors.done : colors.fgMuted)

                if !granted {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Text("Open settings")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(colors.accentInk)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    Swift.Task {
                        let granted = await NotificationService.shared.requestPermission()
                        settings.notificationsEnabled = granted
                        withAnimation(.easeInOut(duration: 0.3)) {
                            notificationsGranted = granted
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 17))
                        Text("Enable Notifications")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(colors.bg)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(colors.fg)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        HStack {
            if currentStep > 0 {
                Button {
                    goToPreviousStep()
                } label: {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(colors.fgMuted)
                        .frame(width: 50, height: 50)
                        .background(colors.surfaceAlt)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                if isLastStep {
                    finishOnboarding()
                } else {
                    goToNextStep()
                }
            } label: {
                HStack(spacing: 8) {
                    Text(isLastStep ? "Get Started" : "Next")
                        .font(.system(size: 17, weight: .medium))
                    if !isLastStep {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 15, weight: .medium))
                    }
                }
                .foregroundStyle(colors.bg)
                .padding(.horizontal, 28)
                .frame(height: 50)
                .background(colors.fg)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Navigation

    private func goToNextStep() {
        withAnimation(.easeIn(duration: 0.15)) {
            contentOpacity = 0
            contentOffset = -15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep += 1
            contentOffset = 30
            animateIn()
        }
    }

    private func goToPreviousStep() {
        withAnimation(.easeIn(duration: 0.15)) {
            contentOpacity = 0
            contentOffset = 15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            currentStep -= 1
            contentOffset = -30
            animateIn()
        }
    }

    private func finishOnboarding() {
        withAnimation(.easeIn(duration: 0.4)) {
            contentOpacity = 0
            contentOffset = -20
            if !keepBackground {
                bgOpacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            onComplete()
        }
    }

    private func animateIn() {
        withAnimation(.easeOut(duration: 0.4)) {
            contentOpacity = 1
            contentOffset = 0
        }
    }
}
