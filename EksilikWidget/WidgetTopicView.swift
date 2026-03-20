import SwiftUI
import WidgetKit

struct WidgetTopicView: View {
    let entry: TopicEntry

    @Environment(\.widgetFamily) var family

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
            Text("eksilik")
                .font(.caption2.bold())
                .foregroundColor(.green)

            ForEach(entry.topics.prefix(3)) { topic in
                Link(destination: deepLink(for: topic)) {
                    Text(topic.title)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundColor(.primary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetBackground()
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("eksilik")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                Spacer()
                Text("gundem")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            ForEach(entry.topics.prefix(4)) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Spacer()
                        if !topic.entryCount.isEmpty {
                            Text(topic.entryCount)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetBackground()
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text("eksilik")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                Spacer()
                Text("gundem")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 4)

            ForEach(entry.topics.prefix(10)) { topic in
                Link(destination: deepLink(for: topic)) {
                    HStack {
                        Text(topic.title)
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundColor(.primary)
                        Spacer()
                        if !topic.entryCount.isEmpty {
                            Text(topic.entryCount)
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                Divider()
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .widgetBackground()
    }

    private func deepLink(for topic: WidgetTopic) -> URL {
        let encoded = topic.link.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? topic.link
        return URL(string: "eksilik://topic?link=\(encoded)")!
    }
}

extension View {
    @ViewBuilder
    func widgetBackground() -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            self.containerBackground(.background, for: .widget)
        } else {
            self.background(Color(.systemBackground))
        }
    }
}
