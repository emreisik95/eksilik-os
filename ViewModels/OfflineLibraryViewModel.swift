import Foundation
import UIKit

struct OfflineLibraryItem: Identifiable {
    let topic: OfflineTopic
    let storageSize: Int64
    var id: String { topic.id }
}

@MainActor
final class OfflineLibraryViewModel: ObservableObject {
    @Published var items: [OfflineLibraryItem] = []
    @Published var isLoading = false
    @Published var error: String?

    private let store = OfflineTopicStore.shared
    private let manager = OfflineDownloadManager.shared

    func load() async {
        isLoading = true
        error = nil
        do {
            let topics = try await store.listTopics()
            var loaded: [OfflineLibraryItem] = []
            for topic in topics {
                loaded.append(OfflineLibraryItem(
                    topic: topic,
                    storageSize: await store.storageSize(topicID: topic.id)
                ))
            }
            items = loaded
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func retry(_ topic: OfflineTopic) async {
        do {
            try await manager.retry(topicID: topic.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }

    func cancel(_ topic: OfflineTopic) async {
        await manager.cancel(topicID: topic.id)
        await load()
    }

    func delete(_ topic: OfflineTopic) async {
        do {
            try await manager.delete(topicID: topic.id)
            await load()
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct OfflineRenderedEntry: Identifiable {
    let entry: OfflineEntry
    let attributedContent: NSAttributedString?
    let localImageURLs: [URL]
    let localAvatarURL: URL?
    var id: String { entry.id }
}

@MainActor
final class OfflineTopicReaderViewModel: ObservableObject {
    @Published private(set) var entries: [OfflineRenderedEntry] = []
    @Published private(set) var readState = OfflineReadState()
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?

    private let store: OfflineTopicStore
    private var topicID: String?

    init(store: OfflineTopicStore = .shared) {
        self.store = store
    }

    var visibleEntries: [OfflineRenderedEntry] {
        guard readState.hidesReadEntries else { return entries }
        return entries.filter { !readState.isRead($0.id) }
    }

    var hasDownloadedEntries: Bool {
        !entries.isEmpty
    }

    func isRead(_ entryID: String) -> Bool {
        readState.isRead(entryID)
    }

    func load(topicID: String, theme: AppTheme, preferences: UserPreferences) async {
        guard entries.isEmpty else { return }
        isLoading = true
        error = nil
        do {
            async let storedEntriesTask = store.loadAllEntries(topicID: topicID)
            async let readStateTask = store.loadReadState(topicID: topicID)
            let (storedEntries, storedReadState) = try await (storedEntriesTask, readStateTask)
            var rendered: [OfflineRenderedEntry] = []
            for entry in storedEntries {
                var imageURLs: [URL] = []
                for rawURL in entry.imageURLs {
                    if let local = await store.localMediaURL(topicID: topicID, sourceURL: rawURL) {
                        imageURLs.append(local)
                    }
                }
                let avatarURL: URL?
                if let rawAvatar = entry.authorAvatarURL {
                    avatarURL = await store.localMediaURL(topicID: topicID, sourceURL: rawAvatar)
                } else {
                    avatarURL = nil
                }
                rendered.append(OfflineRenderedEntry(
                    entry: entry,
                    attributedContent: HTMLContentRenderer.render(
                        html: entry.contentHTML,
                        fontSize: preferences.selectedFontSize,
                        fontName: preferences.selectedFont,
                        textColorHex: theme.entryTextColor.hexString,
                        linkColorHex: theme.linkColor.hexString,
                        spoilerBgHex: theme.spoilerBackgroundHex
                    ),
                    localImageURLs: imageURLs,
                    localAvatarURL: avatarURL
                ))
            }
            entries = rendered
            readState = storedReadState
            self.topicID = topicID
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func toggleRead(entryID: String) async {
        guard let topicID else { return }
        do {
            readState = try await store.setEntryRead(
                topicID: topicID,
                entryID: entryID,
                isRead: !readState.isRead(entryID)
            )
        } catch {
            self.error = error.localizedDescription
        }
    }

    func toggleHidingReadEntries() async {
        guard let topicID else { return }
        do {
            readState = try await store.setHidesReadEntries(
                topicID: topicID,
                hides: !readState.hidesReadEntries
            )
        } catch {
            self.error = error.localizedDescription
        }
    }
}
