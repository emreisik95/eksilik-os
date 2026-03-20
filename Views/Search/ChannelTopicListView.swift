import SwiftUI

struct ChannelTopicListView: View {
    let link: String
    let title: String

    @EnvironmentObject var themeManager: ThemeManager
    @State private var topics: [Topic] = []
    @State private var isLoading = false
    @State private var error: String?

    var body: some View {
        Group {
            if isLoading && topics.isEmpty {
                LoadingView()
            } else if let error, topics.isEmpty {
                ErrorView(message: error) {
                    Task { await load() }
                }
            } else {
                List {
                    ForEach(Array(topics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink(value: Route.entryList(link: topic.link, title: topic.title)) {
                            TopicRowView(topic: topic, isEven: index % 2 == 0)
                        }
                        .listRowBackground(
                            index % 2 == 0
                            ? themeManager.current.cellPrimaryColor
                            : themeManager.current.cellSecondaryColor
                        )
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            let html = try await HTTPClient.shared.fetchHTML(for: .topic(slug: link, page: nil))
            topics = TopicListParser.parse(html: html)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}
