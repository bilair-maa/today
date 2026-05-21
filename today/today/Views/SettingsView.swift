import SwiftUI

// Lets the user change theme, appearance mode, notification preferences, and day start hour.
struct SettingsView: View {
    @ObservedObject var viewModel: TaskViewModel
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // Staged value so the user can preview before committing with the confirmation dialog
    @State private var pendingDayStartHour: Int?
    @State private var showDayStartConfirmation = false

    private var colors: TodayColors {
        .colors(for: settings.palette, scheme: settings.effectiveColorScheme(from: colorScheme))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Settings")
                        .font(.system(size: 48, weight: .regular, design: .serif))
                        .tracking(-0.5)
                        .foregroundStyle(colors.fg)

                    themeSection
                    modeSection
                    notificationsSection
                    dayStartSection
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(colors.bg)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(colors.bg, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Today")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundStyle(colors.fg)
                    }
                }
            }
        }
    }

    // MARK: - Theme

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THEME")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            HStack(spacing: 12) {
                ForEach(ThemePalette.allCases, id: \.self) { palette in
                    themePreview(palette)
                }
            }
        }
    }

    private func themePreview(_ palette: ThemePalette) -> some View {
        let isSelected = settings.palette == palette
        let preview = TodayColors.colors(for: palette, scheme: colorScheme)

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                settings.palette = palette
            }
        } label: {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(preview.bg)
                    .aspectRatio(1.1, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(preview.fg)
                                .frame(width: 14, height: 14)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(preview.fgMuted)
                                .frame(width: 32, height: 3)
                            RoundedRectangle(cornerRadius: 2)
                                .fill(preview.fgFaint)
                                .frame(width: 22, height: 3)
                        }
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(isSelected ? colors.accent : Color.clear, lineWidth: 2)
                    }

                Text(palette.rawValue.capitalized)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? colors.fg : colors.fgMuted)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Mode

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("MODE")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            HStack(spacing: 8) {
                ForEach(AppearanceMode.allCases, id: \.self) { mode in
                    modeButton(mode)
                }
            }
        }
    }

    private func modeButton(_ mode: AppearanceMode) -> some View {
        let isSelected = settings.appearanceMode == mode

        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                settings.appearanceMode = mode
            }
        } label: {
            HStack(spacing: 6) {
                if mode == .light {
                    Image(systemName: "sun.max")
                        .font(.system(size: 15))
                }
                if mode == .dark {
                    Image(systemName: "moon")
                        .font(.system(size: 15))
                }
                Text(mode.rawValue.capitalized)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(isSelected ? colors.bg : colors.fgMuted)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(isSelected ? colors.accentInk : colors.surfaceAlt)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Notifications

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NOTIFICATIONS")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Push Notifications")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(colors.fg)

                    Text("Daily check-ins, priority reminders, and expiration alerts.")
                        .font(.system(size: 14))
                        .foregroundStyle(colors.fgMuted)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        if newValue {
                            Swift.Task {
                                let granted = await viewModel.enableNotifications()
                                settings.notificationsEnabled = granted
                            }
                        } else {
                            settings.notificationsEnabled = false
                            viewModel.disableNotifications()
                        }
                    }
                ))
                .labelsHidden()
                .tint(colors.accentInk)
            }
        }
    }

    // MARK: - Day Start

    private var displayedDayStartHour: Int {
        pendingDayStartHour ?? settings.dayStartHour
    }

    private static let allowedDayStartHours = Array(0...10)

    private var dayStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAY STARTS AT")
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .tracking(1.4)
                .foregroundStyle(colors.fgFaint)

            HStack {
                Text(formattedHour(displayedDayStartHour))
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(colors.fg)
                    .contentTransition(.numericText())

                Spacer()

                HStack(spacing: 0) {
                    Button {
                        guard let currentIndex = Self.allowedDayStartHours.firstIndex(of: displayedDayStartHour),
                              currentIndex > 0 else { return }
                        let newHour = Self.allowedDayStartHours[currentIndex - 1]
                        if newHour != settings.dayStartHour {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                pendingDayStartHour = newHour
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                pendingDayStartHour = nil
                            }
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(displayedDayStartHour == Self.allowedDayStartHours.first ? colors.fgFaint : colors.fgMuted)
                            .frame(width: 44, height: 40)
                    }
                    .disabled(displayedDayStartHour == Self.allowedDayStartHours.first)

                    Rectangle()
                        .fill(colors.hairline)
                        .frame(width: 1, height: 20)

                    Button {
                        guard let currentIndex = Self.allowedDayStartHours.firstIndex(of: displayedDayStartHour),
                              currentIndex < Self.allowedDayStartHours.count - 1 else { return }
                        let newHour = Self.allowedDayStartHours[currentIndex + 1]
                        if newHour != settings.dayStartHour {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                pendingDayStartHour = newHour
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                pendingDayStartHour = nil
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(displayedDayStartHour == Self.allowedDayStartHours.last ? colors.fgFaint : colors.fgMuted)
                            .frame(width: 44, height: 40)
                    }
                    .disabled(displayedDayStartHour == Self.allowedDayStartHours.last)
                }
                .background(colors.surfaceAlt)
                .clipShape(Capsule())
            }

            Text("If your day runs past midnight, push this back. Tasks won\u{2019}t reset until this time.")
                .font(.system(size: 15))
                .foregroundStyle(colors.fgMuted)

            if pendingDayStartHour != nil {
                Button {
                    showDayStartConfirmation = true
                } label: {
                    Text("Apply change")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(colors.bg)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(colors.fg)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .alert("Change day start?", isPresented: $showDayStartConfirmation) {
            Button("Change") {
                if let newHour = pendingDayStartHour {
                    settings.dayStartHour = newHour
                    pendingDayStartHour = nil
                }
            }
            Button("Cancel", role: .cancel) {
                pendingDayStartHour = nil
            }
        } message: {
            Text("Your tasks will reset at \(formattedHour(pendingDayStartHour ?? settings.dayStartHour)). Are you sure?")
        }
    }

    private func formattedHour(_ hour: Int) -> String {
        let h = hour % 12 == 0 ? 12 : hour % 12
        let period = hour < 12 ? "AM" : "PM"
        return "\(h):00 \(period)"
    }
}

#Preview {
    SettingsView(viewModel: TaskViewModel())
        .environmentObject(AppSettings())
}
