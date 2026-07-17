import Foundation
import UIKit

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var isLoadingEntries = false
    @Published var hasMoreEntries = true
    @Published var error: String?
    @Published var selectedTab: ProfileTab = .entries
    private var currentPage = 1
    private var currentFilter = "son-entryleri"
    private var entriesGeneration = UUID()

    enum ProfileTab: String, CaseIterable {
        case entries = "son-entryleri"
        case favorites = "favori-entryleri"
        case images = "gorselleri"

        var title: String {
            switch self {
            case .entries: return L10n.Profile.entries
            case .favorites: return L10n.Profile.favorites
            case .images: return L10n.Profile.images
            }
        }
    }

    let statsOptions: [(String, String)] = [
        ("en çok favorilenenler", "en-cok-favorilenen-entryleri"),
        ("son oylananları", "son-oylananlari"),
        ("bu hafta dikkat çekenleri", "bu-hafta-dikkat-cekenleri"),
        ("el emeği göz nuru", "el-emegi-goz-nuru"),
        ("en beğenilenleri", "en-begenilenleri"),
    ]

    private let userService = UserService()
    private let entryService = EntryService()
    let username: String

    init(username: String) {
        self.username = username
    }

    func loadProfile() async {
        guard profile == nil, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            let result = try await userService.fetchProfile(username: username)
            profile = result
            prefetchImages()
            // Entries are loaded separately via AJAX tab endpoints
            await loadEntries(filter: selectedTab.rawValue)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func selectTab(_ tab: ProfileTab) async {
        guard selectedTab != tab || currentFilter != tab.rawValue || profile?.entries.isEmpty == true else {
            return
        }
        selectedTab = tab
        await loadEntries(filter: tab.rawValue)
    }

    func loadStatsFilter(_ filter: String) async {
        await loadEntries(filter: filter)
    }

    private func loadEntries(filter: String) async {
        let generation = UUID()
        entriesGeneration = generation
        currentFilter = filter
        currentPage = 1
        hasMoreEntries = true
        isLoadingEntries = true
        isLoadingMore = false
        error = nil
        do {
            let entries = try await userService.fetchProfileEntries(username: username, filter: filter, page: 1)
            guard entriesGeneration == generation, currentFilter == filter else { return }
            let parsed = UserProfile.ProfileEntry.orderedUnique(preParseEntries(entries))
            profile?.entries = parsed
            hasMoreEntries = !parsed.isEmpty
            prefetchImages()
        } catch {
            guard entriesGeneration == generation else { return }
            self.error = error.localizedDescription
        }
        if entriesGeneration == generation {
            isLoadingEntries = false
        }
    }

    func loadMoreEntries() async {
        guard !isLoadingMore, !isLoadingEntries, hasMoreEntries else { return }
        let generation = entriesGeneration
        let filter = currentFilter
        let nextPage = currentPage + 1
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let entries = try await userService.fetchProfileEntries(username: username, filter: filter, page: nextPage)
            guard entriesGeneration == generation, currentFilter == filter else { return }
            let parsed = preParseEntries(entries)
            let existing = profile?.entries ?? []
            let merged = UserProfile.ProfileEntry.orderedUnique(existing + parsed)
            let addedCount = merged.count - existing.count
            if parsed.isEmpty || addedCount == 0 {
                hasMoreEntries = false
            } else {
                currentPage = nextPage
                profile?.entries = merged
                prefetchImages()
            }
        } catch {
            guard entriesGeneration == generation else { return }
            self.error = error.localizedDescription
        }
    }

    func vote(for entry: UserProfile.ProfileEntry, rate: Int) async {
        guard let index = profile?.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        let currentState = entry.voteState
        do {
            if (rate == 1 && currentState == .upvoted) || (rate == -1 && currentState == .downvoted) {
                try await entryService.removeVote(entryId: entry.id, rate: rate)
                profile?.entries[index].voteState = .none
            } else {
                try await entryService.vote(entryId: entry.id, rate: rate)
                profile?.entries[index].voteState = rate == 1 ? .upvoted : .downvoted
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func deleteEntry(id: String) async {
        do {
            try await entryService.deleteEntry(id: id)
            profile?.entries.removeAll { $0.id == id }
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleFavorite(for entry: UserProfile.ProfileEntry) async {
        guard let index = profile?.entries.firstIndex(where: { $0.id == entry.id }) else { return }
        do {
            if entry.isFavorited {
                try await entryService.unfavorite(entryId: entry.id)
                profile?.entries[index].isFavorited = false
                profile?.entries[index].favoriteCount -= 1
            } else {
                try await entryService.favorite(entryId: entry.id)
                profile?.entries[index].isFavorited = true
                profile?.entries[index].favoriteCount += 1
            }
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func preParseEntries(_ raw: [UserProfile.ProfileEntry]) -> [UserProfile.ProfileEntry] {
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
        guard let profile else { return }
        let urls = [profile.avatarURL].compactMap { $0 }
            + profile.badges.map(\.imageURL)
            + profile.entries.flatMap(\.imageURLs)
        Task { await ImagePipeline.shared.prefetch(urls) }
    }
}
