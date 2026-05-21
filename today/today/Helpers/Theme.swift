import SwiftUI

// MARK: - Theme Configuration

enum ThemePalette: String, Codable, CaseIterable {
    case warm, cool
}

enum AppearanceMode: String, Codable, CaseIterable {
    case system, light, dark
}

// MARK: - Color Tokens

// Each theme variant (warm/cool x light/dark) defines a full set of semantic colors.
// Views use these tokens so the whole UI stays consistent when the theme changes.

struct TodayColors {
    let bg: Color
    let surface: Color
    let surfaceAlt: Color
    let fg: Color
    let fgMuted: Color
    let fgFaint: Color
    let accent: Color
    let accentSoft: Color
    let accentInk: Color
    let done: Color
    let warn: Color
    let hairline: Color
    let divider: Color

    static func colors(for palette: ThemePalette, scheme: ColorScheme) -> TodayColors {
        switch (palette, scheme) {
        case (.warm, .light): return warmLight
        case (.warm, .dark): return warmDark
        case (.cool, .light): return coolLight
        case (.cool, .dark): return coolDark
        @unknown default: return warmLight
        }
    }

    static let warmLight = TodayColors(
        bg:         Color(red: 0.953, green: 0.945, blue: 0.929),
        surface:    Color(red: 0.980, green: 0.973, blue: 0.961),
        surfaceAlt: Color(red: 0.922, green: 0.910, blue: 0.886),
        fg:         Color(red: 0.165, green: 0.153, blue: 0.141),
        fgMuted:    Color(red: 0.514, green: 0.494, blue: 0.459),
        fgFaint:    Color(red: 0.710, green: 0.694, blue: 0.663),
        accent:     Color(red: 0.612, green: 0.580, blue: 0.541),
        accentSoft: Color(red: 0.867, green: 0.851, blue: 0.824),
        accentInk:  Color(red: 0.353, green: 0.329, blue: 0.298),
        done:       Color(red: 0.478, green: 0.451, blue: 0.408),
        warn:       Color(red: 0.710, green: 0.541, blue: 0.435),
        hairline:   Color(red: 0.165, green: 0.153, blue: 0.141).opacity(0.08),
        divider:    Color(red: 0.165, green: 0.153, blue: 0.141).opacity(0.06)
    )

    static let warmDark = TodayColors(
        bg:         Color(red: 0.102, green: 0.094, blue: 0.086),
        surface:    Color(red: 0.133, green: 0.122, blue: 0.110),
        surfaceAlt: Color(red: 0.165, green: 0.153, blue: 0.133),
        fg:         Color(red: 0.922, green: 0.906, blue: 0.875),
        fgMuted:    Color(red: 0.588, green: 0.561, blue: 0.514),
        fgFaint:    Color(red: 0.365, green: 0.341, blue: 0.302),
        accent:     Color(red: 0.694, green: 0.659, blue: 0.604),
        accentSoft: Color(red: 0.173, green: 0.161, blue: 0.133),
        accentInk:  Color(red: 0.847, green: 0.816, blue: 0.749),
        done:       Color(red: 0.580, green: 0.541, blue: 0.494),
        warn:       Color(red: 0.757, green: 0.612, blue: 0.502),
        hairline:   Color(red: 0.922, green: 0.906, blue: 0.875).opacity(0.08),
        divider:    Color(red: 0.922, green: 0.906, blue: 0.875).opacity(0.06)
    )

    static let coolLight = TodayColors(
        bg:         Color(red: 0.945, green: 0.953, blue: 0.957),
        surface:    Color(red: 0.980, green: 0.984, blue: 0.988),
        surfaceAlt: Color(red: 0.902, green: 0.910, blue: 0.922),
        fg:         Color(red: 0.145, green: 0.153, blue: 0.165),
        fgMuted:    Color(red: 0.478, green: 0.494, blue: 0.514),
        fgFaint:    Color(red: 0.690, green: 0.702, blue: 0.722),
        accent:     Color(red: 0.565, green: 0.604, blue: 0.639),
        accentSoft: Color(red: 0.847, green: 0.863, blue: 0.878),
        accentInk:  Color(red: 0.302, green: 0.325, blue: 0.357),
        done:       Color(red: 0.431, green: 0.459, blue: 0.486),
        warn:       Color(red: 0.627, green: 0.522, blue: 0.467),
        hairline:   Color(red: 0.145, green: 0.153, blue: 0.165).opacity(0.08),
        divider:    Color(red: 0.145, green: 0.153, blue: 0.165).opacity(0.06)
    )

    static let coolDark = TodayColors(
        bg:         Color(red: 0.086, green: 0.094, blue: 0.102),
        surface:    Color(red: 0.114, green: 0.122, blue: 0.133),
        surfaceAlt: Color(red: 0.145, green: 0.157, blue: 0.169),
        fg:         Color(red: 0.910, green: 0.918, blue: 0.929),
        fgMuted:    Color(red: 0.549, green: 0.565, blue: 0.584),
        fgFaint:    Color(red: 0.337, green: 0.353, blue: 0.376),
        accent:     Color(red: 0.659, green: 0.694, blue: 0.733),
        accentSoft: Color(red: 0.161, green: 0.173, blue: 0.188),
        accentInk:  Color(red: 0.784, green: 0.808, blue: 0.835),
        done:       Color(red: 0.537, green: 0.561, blue: 0.588),
        warn:       Color(red: 0.702, green: 0.580, blue: 0.498),
        hairline:   Color(red: 0.910, green: 0.918, blue: 0.929).opacity(0.08),
        divider:    Color(red: 0.910, green: 0.918, blue: 0.929).opacity(0.06)
    )
}

// MARK: - Priority Colors

extension Priority {
    var color: Color {
        switch self {
        case .low: return Color(red: 0.38, green: 0.65, blue: 0.58)
        case .medium: return Color(red: 0.80, green: 0.62, blue: 0.30)
        case .high: return Color(red: 0.82, green: 0.32, blue: 0.32)
        }
    }
}
