import SwiftUI

// Shown when there are no tasks yet. Prompts the user to add their first one.
struct EmptyStateView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.colorScheme) private var colorScheme

    private var colors: TodayColors {
        .colors(for: settings.palette, scheme: settings.effectiveColorScheme(from: colorScheme))
    }

    var body: some View {
        VStack(spacing: 0) {
            Text("Today is open.")
                .font(.system(size: 30, weight: .regular, design: .serif))
                .tracking(-0.3)
                .foregroundStyle(colors.fg)
                .padding(.top, 16)

            Text("Add one small thing you\u{2019}d like to do.")
                .font(.system(size: 17))
                .foregroundStyle(colors.fgMuted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 260)
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    EmptyStateView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.953, green: 0.945, blue: 0.929))
        .environmentObject(AppSettings())
}
