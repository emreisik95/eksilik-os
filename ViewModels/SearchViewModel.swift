import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var titles: [String] = []
    @Published var nicks: [String] = []
    @Published var isSearching = false
    @Published var channels: [Channel] = []
    @Published var isLoadingChannels = false

    private let searchService = SearchService()
    private let client = HTTPClient.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        guard query.count >= 2 else {
            titles = []
            nicks = []
            isSearching = false
            return
        }

        let requestedQuery = query
        searchTask = Task {
            isSearching = true
            do {
                let result = try await searchService.search(query: requestedQuery)
                if !Task.isCancelled, query == requestedQuery {
                    titles = result.titles
                    nicks = result.nicks
                }
            } catch {
                if !Task.isCancelled, query == requestedQuery {
                    titles = []
                    nicks = []
                }
            }
            if query == requestedQuery {
                isSearching = false
            }
        }
    }

    func loadChannels() async {
        guard channels.isEmpty, !isLoadingChannels else { return }
        isLoadingChannels = true
        defer {
            isLoadingChannels = false
        }
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
            let csrfToken = SessionManager.shared.csrfToken
            try await client.post(endpoint: endpoint, body: ["name": channel.id], csrfToken: csrfToken)
            channels[index].isFollowed.toggle()
        } catch {
            // silently fail
        }
    }

    func resolveQuery() -> Route? {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
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
