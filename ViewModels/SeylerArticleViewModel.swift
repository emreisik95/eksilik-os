import Foundation

extension Notification.Name {
    static let offlineSeylerDidChange = Notification.Name("offlineSeylerDidChange")
}

@MainActor
final class SeylerArticleViewModel: ObservableObject {
    @Published var article: SeylerArticle?
    @Published var isLoading = false
    @Published var error: String?
    @Published private(set) var isSaved = false
    @Published private(set) var isSaving = false
    @Published private(set) var localMediaURLs: [URL: URL] = [:]

    let sourceURL: URL
    private let service: SeylerService
    private let store: OfflineSeylerStore

    init(
        url: URL,
        service: SeylerService = SeylerService(),
        store: OfflineSeylerStore = .shared
    ) {
        sourceURL = url
        self.service = service
        self.store = store
    }

    func loadArticle(force: Bool = false) async {
        guard force || article == nil else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        if !force, let saved = try? await store.loadArticle(sourceURL: sourceURL) {
            await apply(saved)
            return
        }

        do {
            let fetched = try await service.fetchArticle(url: sourceURL)
            article = fetched
            isSaved = await store.contains(sourceURL: fetched.sourceURL)
            if isSaved, force,
               let updated = try? await store.saveArticleAndMedia(fetched) {
                await apply(updated)
            } else {
                localMediaURLs = [:]
            }
        } catch {
            if article == nil,
               let saved = try? await store.loadArticle(sourceURL: sourceURL) {
                await apply(saved)
            } else {
                self.error = error.localizedDescription
            }
        }
    }

    func saveForOffline() async {
        guard let article, !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            let saved = try await store.saveArticleAndMedia(article)
            await apply(saved)
            NotificationCenter.default.post(name: .offlineSeylerDidChange, object: nil)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func removeOfflineCopy() async {
        guard !isSaving else { return }
        isSaving = true
        error = nil
        defer { isSaving = false }

        do {
            let id = OfflineIdentifier.value(for: sourceURL.absoluteString)
            try await store.deleteArticle(id: id)
            isSaved = false
            localMediaURLs = [:]
            NotificationCenter.default.post(name: .offlineSeylerDidChange, object: nil)
        } catch {
            self.error = error.localizedDescription
        }
    }

    func displayURL(for sourceURL: URL) -> URL {
        localMediaURLs[sourceURL] ?? sourceURL
    }

    func galleryURLs(for article: SeylerArticle) -> [URL] {
        article.imageURLs.map(displayURL(for:))
    }

    private func apply(_ saved: OfflineSeylerArticle) async {
        article = saved.article
        isSaved = true
        var resolved: [URL: URL] = [:]
        for sourceURL in saved.article.imageURLs {
            if let local = await store.localMediaURL(
                articleID: saved.id,
                sourceURL: sourceURL
            ) {
                resolved[sourceURL] = local
            }
        }
        localMediaURLs = resolved
    }
}
