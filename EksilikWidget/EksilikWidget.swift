import WidgetKit
import SwiftUI

struct EksilikWidget: Widget {
    let kind = "EksilikWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PopularTopicsProvider()) { entry in
            WidgetTopicView(entry: entry)
        }
        .configurationDisplayName("Popular Topics")
        .description("Shows trending topics from Eksi Sozluk.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}
