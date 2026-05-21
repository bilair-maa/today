import WidgetKit
import SwiftUI

struct TodayWidget: Widget {
    let kind = "todayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Your daily tasks at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
