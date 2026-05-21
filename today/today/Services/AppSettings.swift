import SwiftUI
import Combine
import WidgetKit

// Stores user preferences and syncs relevant ones to the widget via shared UserDefaults.
class AppSettings: ObservableObject {
    private static let suiteName = "group.com.shahana.today"

    private var shared: UserDefaults? { UserDefaults(suiteName: Self.suiteName) }

    @Published var palette: ThemePalette {
        didSet {
            UserDefaults.standard.set(palette.rawValue, forKey: "themePalette")
            shared?.set(palette.rawValue, forKey: "themePalette")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }
    @Published var dayStartHour: Int {
        didSet {
            UserDefaults.standard.set(dayStartHour, forKey: "dayStartHour")
            shared?.set(dayStartHour, forKey: "dayStartHour")
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    @Published var lastWelcomeDate: String {
        didSet { UserDefaults.standard.set(lastWelcomeDate, forKey: "lastWelcomeDate") }
    }
    @Published var notificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled") }
    }
    @Published var hasCompletedOnboarding: Bool {
        didSet { UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    init() {
        let paletteRaw = UserDefaults.standard.string(forKey: "themePalette") ?? "warm"
        self.palette = ThemePalette(rawValue: paletteRaw) ?? .warm
        let modeRaw = UserDefaults.standard.string(forKey: "appearanceMode") ?? "system"
        self.appearanceMode = AppearanceMode(rawValue: modeRaw) ?? .system
        self.dayStartHour = UserDefaults.standard.integer(forKey: "dayStartHour")
        self.lastWelcomeDate = UserDefaults.standard.string(forKey: "lastWelcomeDate") ?? ""
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        syncToSharedDefaults()
    }

    // Push theme and day start hour to the widget's shared container
    private func syncToSharedDefaults() {
        shared?.set(palette.rawValue, forKey: "themePalette")
        shared?.set(dayStartHour, forKey: "dayStartHour")
    }

    // Whether the user hasn't seen today's welcome screen yet
    var shouldShowNewDayWelcome: Bool {
        lastWelcomeDate != todaysDateString(dayStartHour: dayStartHour)
    }

    func markWelcomeShown() {
        lastWelcomeDate = todaysDateString(dayStartHour: dayStartHour)
    }

    var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func effectiveColorScheme(from system: ColorScheme) -> ColorScheme {
        preferredColorScheme ?? system
    }
}
