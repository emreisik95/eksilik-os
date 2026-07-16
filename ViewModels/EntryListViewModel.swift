import Foundation
import UIKit

@MainActor
final class EntryListViewModel: ObservableObject {
    @Published var title = ""
    @Published var entries: [Entry] = []
    @Published var pagination: Pagination = .empty
    @Published var isLoading = false
    @Published var error: String?
    @Published var showAllLinks: [(text: String, link: String)] = []
    @Published var activeFilter: EntryFilter = .none
    @Published var isTracked = false

    private let entryService = EntryService()
    var topicLink: String { currentRequest.settingPage(nil).pathAndQuery }
    var offlineRequest: TopicRequest { currentRequest.settingPage(nil) }
    var offlineTotalPages: Int { max(1, pagination.totalPages) }
    private var currentRequest: TopicRequest
    private var topicSlug = ""
    private var topicId = ""
    private var loadGeneration = UUID()

    init(link: String) {
        self.currentRequest = TopicRequest(link: link)
    }

    /// Apply a filter and reload entries
    func applyFilter(_ filter: EntryFilter) async {
        activeFilter = filter
        if !topicSlug.isEmpty {
            currentRequest = currentRequest.replacingPath(topicSlug)
        }
        currentRequest = currentRequest.applying(filter: filter)
        await loadEntries()
    }

    func loadEntries() async {
        let generation = UUID()
        loadGeneration = generation
        isLoading = true
        error = nil

        do {
            let page = try await entryService.fetchEntries(request: currentRequest)
            guard loadGeneration == generation else { return }
            title = page.title
            pagination = page.pagination
            topicSlug = page.slug
            topicId = page.topicId
            isTracked = page.isTracked
            if !page.slug.isEmpty {
                currentRequest = currentRequest.replacingPath(page.slug)
            }
            showAllLinks = page.showAllLinks
            entries = preParseEntries(page.entries)
            prefetchImages()
        } catch {
            guard loadGeneration == generation else { return }
            self.error = error.localizedDescription
        }

        if loadGeneration == generation {
            isLoading = false
        }
    }

    func goToPage(_ page: Int) async {
        let generation = UUID()
        loadGeneration = generation
        isLoading = true
        error = nil

        do {
            let requestedPage = currentRequest.settingPage(page)
            let result = try await entryService.fetchEntriesAtPage(request: currentRequest, page: page)
            guard loadGeneration == generation else { return }
            currentRequest = requestedPage
            title = result.title
            pagination = result.pagination
            topicSlug = result.slug
            topicId = result.topicId
            isTracked = result.isTracked
            if !result.slug.isEmpty {
                currentRequest = currentRequest.replacingPath(result.slug)
            }
            showAllLinks = result.showAllLinks
            entries = preParseEntries(result.entries)
            prefetchImages()
        } catch {
            guard loadGeneration == generation else { return }
            self.error = error.localizedDescription
        }

        if loadGeneration == generation {
            isLoading = false
        }
    }

    /// Pre-parse HTML content to NSAttributedString before displaying
    private func preParseEntries(_ raw: [Entry]) -> [Entry] {
        let theme = ThemeManager().current
        let prefs = UserPreferences()

        return raw.map { entry in
            var e = entry
            e.parsedContent = HTMLContentRenderer.render(
                html: entry.contentHTML,
                fontSize: prefs.selectedFontSize,
                fontName: prefs.selectedFont,
                textColorHex: theme.entryTextColor.hexString,
                linkColorHex: theme.linkColor.hexString,
                spoilerBgHex: theme.spoilerBackgroundHex
            )
            return e
        }
    }

    private func prefetchImages() {
        let urls = entries.flatMap(\.imageURLs) + entries.compactMap { $0.author.avatarURL }
        Task { await ImagePipeline.shared.prefetch(urls) }
    }

    func toggleFavorite(for entry: Entry) async {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }

        do {
            if entries[index].isFavorited {
                try await entryService.unfavorite(entryId: entry.id)
                entries[index].isFavorited = false
                entries[index].favoriteCount -= 1
            } else {
                try await entryService.favorite(entryId: entry.id)
                entries[index].isFavorited = true
                entries[index].favoriteCount += 1
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func vote(for entry: Entry, rate: Int) async {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }

        let currentState = entries[index].voteState
        do {
            if (rate == 1 && currentState == .upvoted) || (rate == -1 && currentState == .downvoted) {
                try await entryService.removeVote(entryId: entry.id, rate: rate)
                entries[index].voteState = .none
            } else {
                try await entryService.vote(entryId: entry.id, rate: rate)
                entries[index].voteState = rate == 1 ? .upvoted : .downvoted
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleTracking() async {
        guard !topicId.isEmpty else { return }

        do {
            if isTracked {
                try await entryService.untrackTopic(id: topicId)
            } else {
                try await entryService.trackTopic(id: topicId)
            }
            isTracked.toggle()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteEntry(id: String) async {
        do {
            try await entryService.deleteEntry(id: id)
            entries.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
