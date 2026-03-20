import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var titles: [String] = []
    @Published var nicks: [String] = []
    @Published var isSearching = false
    @Published var channels: [Channel] = []

    private let searchService = SearchService()
    private let client = HTTPClient.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        guard query.count >= 2 else {
            titles = []
            nicks = []
            return
        }

        searchTask = Task {
            isSearching = true
            do {
                let result = try await searchService.search(query: query)
                if !Task.isCancelled {
                    titles = result.titles
                    nicks = result.nicks
                }
            } catch {
                if !Task.isCancelled {
                    titles = []
                    nicks = []
                }
            }
            isSearching = false
        }
    }

    func loadChannels() async {
        guard channels.isEmpty else { return }
        do {
            let html = try await client.fetchHTML(for: .channels)
            channels = ChannelParser.parse(html: html)
        } catch {
            // silently fail — channels are optional
        }
    }

    func toggleFollow(channel: Channel) async {
        guard let index = channels.firstIndex(where: { $0.id == channel.id }) else { return }
        let endpoint: EksiEndpoint = channel.isFollowed
            ? .channelUnfollow(slug: channel.id)
            : .channelFollow(slug: channel.id)
        do {
            let csrfToken = await SessionManager.shared.csrfToken
            try await client.post(endpoint: endpoint, body: ["name": channel.id], csrfToken: csrfToken)
            channels[index].isFollowed.toggle()
        } catch {
            // silently fail
        }
    }

    func resolveQuery() -> Route? {
        let text = query.trimmingCharacters(in: .whitespaces)
        if text.hasPrefix("#"), let _ = Int(text.dropFirst()) {
            return .entryById(id: String(text.dropFirst()))
        }
        if text.hasPrefix("@") {
            return .profile(username: String(text.dropFirst()))
        }
        let encoded = text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? text
        return .entryList(link: encoded, title: text)
    }
}
