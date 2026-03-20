import Foundation
import UIKit

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var error: String?
    @Published var selectedTab: ProfileTab = .entries

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
        isLoading = true
        error = nil

        do {
            let result = try await userService.fetchProfile(username: username)
            profile = result
            // Entries are loaded separately via AJAX tab endpoints
            await loadEntries(filter: selectedTab.rawValue)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }

    func selectTab(_ tab: ProfileTab) async {
        selectedTab = tab
        await loadEntries(filter: tab.rawValue)
    }

    func loadStatsFilter(_ filter: String) async {
        await loadEntries(filter: filter)
    }

    private func loadEntries(filter: String) async {
        do {
            let entries = try await userService.fetchProfileEntries(username: username, filter: filter)
            profile?.entries = preParseEntries(entries)
        } catch {
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
}
