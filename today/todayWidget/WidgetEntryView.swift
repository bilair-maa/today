import SwiftUI
import WidgetKit

// Routes to the right widget layout based on the widget family size
struct WidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    let entry: TaskEntry

    private var colors: WidgetColors {
        .colors(for: entry.palette, scheme: colorScheme)
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                SmallWidgetView(entry: entry, colors: colors)
            case .systemMedium:
                MediumWidgetView(entry: entry, colors: colors)
            case .systemLarge:
                LargeWidgetView(entry: entry, colors: colors)
            default:
                SmallWidgetView(entry: entry, colors: colors)
            }
        }
        .widgetBackground(colors.bg)
    }
}

extension View {
    func widgetBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            return containerBackground(color, for: .widget)
        } else {
            return background(color)
        }
    }
}
