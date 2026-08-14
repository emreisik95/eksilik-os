import Foundation

@MainActor
final class SeylerFeedViewModel: ObservableObject {
    @Published var stories: [SeylerStory] = []
    @Published var selectedCategory: SeylerCategory = .latest
    @Published var isLoading = false
    @Published var error: String?

    private let service: SeylerService
    private var loadGeneration = UUID()

    init(service: SeylerService = SeylerService()) {
        self.service = service
    }

    func loadStories() async {
        let category = selectedCategory
        let generation = UUID()
        loadGeneration = generation
        isLoading = true
        error = nil

        do {
            let incoming = try await service.fetchStories(category: category)
            guard generation == loadGeneration, category == selectedCategory else { return }
            stories = incoming
        } catch {
            guard generation == loadGeneration, category == selectedCategory else { return }
            self.error = error.localizedDescription
        }

        if generation == loadGeneration {
            isLoading = false
        }
    }
}
