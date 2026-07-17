import Foundation
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var titles: [String] = []
    @Published var nicks: [String] = []
    @Published var isSearching = false
    @Published var searchError: String?
    @Published var channels: [Channel] = []
    @Published var isLoadingChannels = false
    @Published var channelError: String?

    private let searchService = SearchService()
    private let client = HTTPClient.shared
    private var searchTask: Task<Void, Never>?

    func search() {
        searchTask?.cancel()

        let normalizedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalizedQuery.count >= 2 else {
            titles = []
            nicks = []
            isSearching = false
            searchError = nil
            return
        }

        let requestedQuery = normalizedQuery
        searchError = nil
        searchTask = Task {
            isSearching = true
            do {
                let result = try await searchService.search(query: requestedQuery)
                if !Task.isCancelled, currentNormalizedQuery == requestedQuery {
                    titles = result.titles
                    nicks = result.nicks
                }
            } catch {
                if !Task.isCancelled, currentNormalizedQuery == requestedQuery {
                    titles = []
                    nicks = []
                    searchError = error.localizedDescription
                }
            }
            if currentNormalizedQuery == requestedQuery {
                isSearching = false
            }
        }
    }

    func loadChannels() async {
        guard channels.isEmpty, !isLoadingChannels else { return }
        isLoadingChannels = true
        channelError = nil
        defer {
            isLoadingChannels = false
        }
        do {
            let html = try await client.fetchHTML(for: .channels)
            channels = ChannelParser.parse(html: html)
        } catch {
            channelError = error.localizedDescription
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
        switch SearchPresentation.resolve(query: query) {
        case .entry(let id):
            return .entryById(id: id)
        case .profile(let username):
            return .profile(username: username)
        case .topic(let link, let title):
            return .entryList(link: link, title: title)
        case nil:
            return nil
        }
    }

    var presentationState: SearchPresentation.State {
        SearchPresentation.state(
            query: query,
            isSearching: isSearching,
            titleCount: titles.count,
            nickCount: nicks.count,
            error: searchError
        )
    }

    private var currentNormalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
