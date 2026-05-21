import SwiftUI

// Widget's own color tokens, separate from the app's TodayColors since the widget
// extension can't import the main target. Uses the same palette values.
struct WidgetColors {
    let bg: Color
    let surface: Color
    let surfaceAlt: Color
    let fg: Color
    let fgMuted: Color
    let fgFaint: Color
    let accent: Color
    let done: Color
    let warn: Color
    let hairline: Color

    static func colors(for palette: String, scheme: ColorScheme) -> WidgetColors {
        switch (palette, scheme) {
        case ("warm", .light): return warmLight
        case ("warm", .dark): return warmDark
        case ("cool", .light): return coolLight
        case ("cool", .dark): return coolDark
        default: return warmLight
        }
    }

    static let warmLight = WidgetColors(
        bg:         Color(red: 0.980, green: 0.973, blue: 0.961),
        surface:    Color(red: 0.953, green: 0.945, blue: 0.929),
        surfaceAlt: Color(red: 0.922, green: 0.910, blue: 0.886),
        fg:         Color(red: 0.165, green: 0.153, blue: 0.141),
        fgMuted:    Color(red: 0.514, green: 0.494, blue: 0.459),
        fgFaint:    Color(red: 0.710, green: 0.694, blue: 0.663),
        accent:     Color(red: 0.612, green: 0.580, blue: 0.541),
        done:       Color(red: 0.478, green: 0.451, blue: 0.408),
        warn:       Color(red: 0.710, green: 0.541, blue: 0.435),
        hairline:   Color(red: 0.165, green: 0.153, blue: 0.141).opacity(0.06)
    )

    static let warmDark = WidgetColors(
        bg:         Color(red: 0.133, green: 0.122, blue: 0.110),
        surface:    Color(red: 0.165, green: 0.153, blue: 0.133),
        surfaceAlt: Color(red: 0.102, green: 0.094, blue: 0.086),
        fg:         Color(red: 0.922, green: 0.906, blue: 0.875),
        fgMuted:    Color(red: 0.588, green: 0.561, blue: 0.514),
        fgFaint:    Color(red: 0.365, green: 0.341, blue: 0.302),
        accent:     Color(red: 0.694, green: 0.659, blue: 0.604),
        done:       Color(red: 0.580, green: 0.541, blue: 0.494),
        warn:       Color(red: 0.757, green: 0.612, blue: 0.502),
        hairline:   Color(red: 0.922, green: 0.906, blue: 0.875).opacity(0.06)
    )

    static let coolLight = WidgetColors(
        bg:         Color(red: 0.980, green: 0.984, blue: 0.988),
        surface:    Color(red: 0.945, green: 0.953, blue: 0.957),
        surfaceAlt: Color(red: 0.902, green: 0.910, blue: 0.922),
        fg:         Color(red: 0.145, green: 0.153, blue: 0.165),
        fgMuted:    Color(red: 0.478, green: 0.494, blue: 0.514),
        fgFaint:    Color(red: 0.690, green: 0.702, blue: 0.722),
        accent:     Color(red: 0.565, green: 0.604, blue: 0.639),
        done:       Color(red: 0.431, green: 0.459, blue: 0.486),
        warn:       Color(red: 0.627, green: 0.522, blue: 0.467),
        hairline:   Color(red: 0.145, green: 0.153, blue: 0.165).opacity(0.06)
    )

    static let coolDark = WidgetColors(
        bg:         Color(red: 0.114, green: 0.122, blue: 0.133),
        surface:    Color(red: 0.145, green: 0.157, blue: 0.169),
        surfaceAlt: Color(red: 0.086, green: 0.094, blue: 0.102),
        fg:         Color(red: 0.910, green: 0.918, blue: 0.929),
        fgMuted:    Color(red: 0.549, green: 0.565, blue: 0.584),
        fgFaint:    Color(red: 0.337, green: 0.353, blue: 0.376),
        accent:     Color(red: 0.659, green: 0.694, blue: 0.733),
        done:       Color(red: 0.537, green: 0.561, blue: 0.588),
        warn:       Color(red: 0.702, green: 0.580, blue: 0.498),
        hairline:   Color(red: 0.910, green: 0.918, blue: 0.929).opacity(0.06)
    )

    func categoryColor(for name: String) -> Color {
        switch name.lowercased() {
        case "work": return accent
        case "home": return done
        case "errand": return warn
        case "self": return fgMuted
        default: return fgFaint
        }
    }
}
