import Foundation

@MainActor
final class SeylerArticleViewModel: ObservableObject {
    @Published var article: SeylerArticle?
    @Published var isLoading = false
    @Published var error: String?

    let sourceURL: URL
    private let service: SeylerService

    init(url: URL, service: SeylerService = SeylerService()) {
        sourceURL = url
        self.service = service
    }

    func loadArticle(force: Bool = false) async {
        guard force || article == nil else { return }
        isLoading = true
        error = nil

        do {
            article = try await service.fetchArticle(url: sourceURL)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
