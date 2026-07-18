import SwiftUI
import WidgetKit

private struct QuickAccessEntry: TimelineEntry {
    let date: Date
}

private struct QuickAccessProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickAccessEntry {
        QuickAccessEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickAccessEntry) -> Void) {
        completion(QuickAccessEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickAccessEntry>) -> Void) {
        completion(Timeline(entries: [QuickAccessEntry(date: Date())], policy: .never))
    }
}

private struct QuickAccessView: View {
    private let shortcuts = [
        (title: "gündem", symbol: "text.line.first.and.arrowtriangle.forward", source: "gundem"),
        (title: "takip", symbol: "person.2", source: "takip"),
        (title: "debe", symbol: "star", source: "debe"),
        (title: "bugün", symbol: "calendar", source: "bugun"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ek$ilik")
                .font(.caption.bold())
                .foregroundStyle(Color(red: 102 / 255, green: 180 / 255, blue: 63 / 255))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(shortcuts, id: \.source) { shortcut in
                    Link(destination: deepLink(source: shortcut.source)) {
                        VStack(spacing: 4) {
                            Image(systemName: shortcut.symbol)
                                .font(.headline)
                            Text(shortcut.title)
                                .font(.caption2.bold())
                        }
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .foregroundStyle(.white)
                        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .padding(12)
        .containerBackground(Color(red: 29 / 255, green: 29 / 255, blue: 29 / 255), for: .widget)
    }

    private func deepLink(source: String) -> URL {
        var components = URLComponents()
        components.scheme = "eksilik"
        components.host = "feed"
        components.queryItems = [URLQueryItem(name: "source", value: source)]
        return components.url ?? URL(fileURLWithPath: "/")
    }
}

struct EksilikQuickAccessWidget: Widget {
    let kind = "EksilikQuickAccessWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickAccessProvider()) { _ in
            QuickAccessView()
        }
        .configurationDisplayName("ek$ilik kısayollar")
        .description("gündem, takip, debe ve bugüne hızlı erişim.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
