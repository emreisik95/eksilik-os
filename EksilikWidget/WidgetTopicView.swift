import SwiftUI
import WidgetKit

struct WidgetTopicView: View {
    let entry: TopicEntry

    @Environment(\.widgetFamily) var family

    private var theme: WidgetTheme { entry.theme }

    private var sourceLabel: String {
        switch entry.source {
        case .gundem: return "gündem"
        case .bugun: return "bugün"
        case .following: return "takip"
        case .debe: return "debe"
        case .caylaklar: return "çaylaklar"
        case .user: return entry.username ?? "kullanıcı"
        }
    }

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                smallView
            case .systemMedium:
                mediumView
            case .systemLarge:
                largeView
            default:
                mediumView
            }
        }
        .privacySensitive(entry.source == .following)
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ek$ilik")
                    .font(.caption2.bold())
                    .foregroundColor(theme.accentColor)
                Spacer()
            }

            ForEach(
                Array(entry.topics.prefix(WidgetPresentationPolicy.topicLimit(for: .small)))
            ) { topic in
                Link(destination: deepLink(for: topic)) {
                    Text(topic.title)
                        .font(.caption)
                        .lineLimit(WidgetPresentationPolicy.titleLineLimit(for: .small))
                        .minimumScaleFactor(0.72)
                        .allowsTightening(true)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(theme.textColor)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .themedBackground(theme: theme)
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ek$ilik")
                    .font(.caption.bold())
                    .foregroundColor(theme.accentColor)
                Spacer()
                Text(sourceLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ForEach(
                Array(entry.topics.prefix(WidgetPresentationPolicy.topicLimit(for: .medium)))
            ) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(WidgetPresentationPolicy.titleLineLimit(for: .medium))
                            .foregroundColor(theme.textColor)
                        Spacer()
                        if let metadata = topic.metadata, !metadata.isEmpty {
                            Text(metadata)
                                .font(.caption2)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                Divider()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .themedBackground(theme: theme)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("ek$ilik")
                    .font(.caption.bold())
                    .foregroundColor(theme.accentColor)
                Spacer()
                Text(sourceLabel)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            ForEach(
                Array(entry.topics.prefix(WidgetPresentationPolicy.topicLimit(for: .large)))
            ) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(WidgetPresentationPolicy.titleLineLimit(for: .large))
                            .foregroundColor(theme.textColor)
                        Spacer()
                        if let metadata = topic.metadata, !metadata.isEmpty {
                            Text(metadata)
                                .font(.caption2)
                                .foregroundColor(theme.accentColor)
                        }
                    }
                }
                Divider()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .themedBackground(theme: theme)
    }

    private func deepLink(for topic: WidgetFeedItem) -> URL {
        if topic.link.isEmpty {
            return feedDeepLink
        }
        if topic.link.hasPrefix("/entry/"),
           let id = topic.link.split(separator: "/").last {
            var components = URLComponents()
            components.scheme = "eksilik"
            components.host = "entry"
            components.path = "/\(id)"
            return components.url ?? feedDeepLink
        }
        var components = URLComponents()
        components.scheme = "eksilik"
        components.host = "topic"
        components.queryItems = [URLQueryItem(name: "link", value: topic.link)]
        return components.url ?? feedDeepLink
    }

    private var feedDeepLink: URL {
        let source: String
        switch entry.source {
        case .gundem: source = "gundem"
        case .bugun: source = "bugun"
        case .following: source = "takip"
        case .debe: source = "debe"
        case .caylaklar: source = "bugun"
        case .user: source = "gundem"
        }
        var components = URLComponents()
        components.scheme = "eksilik"
        components.host = "feed"
        components.queryItems = [URLQueryItem(name: "source", value: source)]
        return components.url ?? URL(fileURLWithPath: "/")
    }
}

extension View {
    @ViewBuilder
    func themedBackground(theme: WidgetTheme) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(theme.bgColor, for: .widget)
        } else {
            self.background(theme.bgColor)
        }
    }
}
