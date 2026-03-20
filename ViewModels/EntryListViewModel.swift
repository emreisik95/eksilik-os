import Foundation
import UIKit

enum EntryFilter: Equatable {
    case none
    case dailyNice
    case eksiseyler
    case links
    case images
    case caylak
    case author(String)
    case search(String)
    case nice
    case niceWeek
    case niceMonth
    case nice3Months
    case niceAllTime

    var queryString: String {
        switch self {
        case .none: return ""
        case .dailyNice: return "?a=dailynice"
        case .eksiseyler: return "?a=eksiseyler"
        case .links: return "?a=find&keywords=http%3a%2f%2f"
        case .images: return "?a=gorseller"
        case .caylak: return "?a=caylaklar"
        case .author(let name): return "?a=search&author=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        case .search(let keywords): return "?a=find&keywords=\(keywords.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? keywords)"
        case .nice: return "?a=nice"
        case .niceWeek: return "?a=nice&period=week"
        case .niceMonth: return "?a=nice&period=month"
        case .nice3Months: return "?a=nice&period=3months"
        case .niceAllTime: return "?a=nice&period=alltime"
        }
    }

    var displayName: String {
        switch self {
        case .none: return "tumu"
        case .dailyNice: return "bugun"
        case .eksiseyler: return "eksi seyler'de"
        case .links: return "linkler"
        case .images: return "gorseller"
        case .caylak: return "caylaklar"
        case .author: return "benimkiler"
        case .search: return "baslikta ara"
        case .nice: return "son 24 saat"
        case .niceWeek: return "son 1 hafta"
        case .niceMonth: return "son 1 ay"
        case .nice3Months: return "son 3 ay"
        case .niceAllTime: return "tumu"
        }
    }
}

@MainActor
final class EntryListViewModel: ObservableObject {
    @Published var title = ""
    @Published var entries: [Entry] = []
    @Published var pagination: Pagination = .empty
    @Published var isLoading = false
    @Published var error: String?
    @Published var showAllLinks: [(text: String, link: String)] = []
    @Published var activeFilter: EntryFilter = .none

    private let entryService = EntryService()
    var topicLink: String
    private(set) var baseTopicLink: String
    private var topicSlug = ""

    init(link: String) {
        self.topicLink = link
        self.baseTopicLink = link
    }

    /// Apply a filter and reload entries
    func applyFilter(_ filter: EntryFilter) async {
        activeFilter = filter
        // Strip any existing query params from base link to get clean slug
        let base = baseTopicLink.components(separatedBy: "?").first ?? baseTopicLink
        topicLink = base + filter.queryString
        await loadEntries()
    }

    func loadEntries() async {
        print("📋 loadTopics called for entries")
        isLoading = true
        error = nil

        do {
            let page = try await entryService.fetchEntries(link: topicLink)
            title = page.title
            pagination = page.pagination
            topicSlug = page.slug
            showAllLinks = page.showAllLinks
            entries = preParseEntries(page.entries)
        } catch {
            print("📋 loadEntries error: \(error)")
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func goToPage(_ page: Int) async {
        isLoading = true
        error = nil

        do {
            let result = try await entryService.fetchEntriesAtPage(link: topicLink, page: page)
            title = result.title
            pagination = result.pagination
            showAllLinks = result.showAllLinks
            entries = preParseEntries(result.entries)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
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

    func deleteEntry(id: String) async {
        do {
            try await entryService.deleteEntry(id: id)
            entries.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
