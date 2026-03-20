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
        case .debe: return "debe"
        case .caylaklar: return "çaylaklar"
        case .user: return entry.username ?? "kullanıcı"
        }
    }

    var body: some View {
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

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("ek$ilik")
                    .font(.caption2.bold())
                    .foregroundColor(theme.accentColor)
                Spacer()
            }

            ForEach(entry.topics.prefix(3)) { topic in
                Link(destination: deepLink(for: topic)) {
                    Text(topic.title)
                        .font(.caption)
                        .lineLimit(1)
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

            ForEach(entry.topics.prefix(4)) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(theme.textColor)
                        Spacer()
                        if !topic.entryCount.isEmpty {
                            Text(topic.entryCount)
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

            ForEach(entry.topics.prefix(10)) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(2)
                            .foregroundColor(theme.textColor)
                        Spacer()
                        if !topic.entryCount.isEmpty {
                            Text(topic.entryCount)
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

    private func deepLink(for topic: WidgetTopic) -> URL {
        let encoded = topic.link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic.link
        return URL(string: "eksilik://topic?link=\(encoded)")!
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
