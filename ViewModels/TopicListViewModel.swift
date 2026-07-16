import Foundation

@MainActor
final class TopicListViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var hasMore = false
    @Published var error: String?
    @Published var pagination: Pagination = .empty

    private let topicService = TopicService()
    private var blockedStore: BlockedTopicStore?
    private var loadGeneration = UUID()

    enum ListType: String {
        case popular, today, todayInHistory, following, latest, debe, kenar, caylaklar, cop
    }

    let listType: ListType
    private var currentPage = 1
    var year: Int?

    init(listType: ListType) {
        self.listType = listType
    }

    func configure(blockedStore: BlockedTopicStore) {
        self.blockedStore = blockedStore
        topics.removeAll { blockedStore.isBlocked($0.title) }
    }

    func loadTopics() async {
        let generation = UUID()
        loadGeneration = generation
        isLoading = true
        isLoadingMore = false
        error = nil
        currentPage = 1

        let filter: (String) -> Bool = { [weak blockedStore] title in
            blockedStore?.isBlocked(title) ?? false
        }

        do {
            let result = try await fetchPage(1, isBlocked: filter)
            guard loadGeneration == generation else { return }
            topics = TopicPageMerger.merge(existing: [], incoming: result.topics)
            pagination = result.pagination
            hasMore = result.pagination.hasNextPage && !result.topics.isEmpty
        } catch {
            guard loadGeneration == generation else { return }
            self.error = error.localizedDescription
        }

        if loadGeneration == generation {
            isLoading = false
        }
    }

    func loadMore() async {
        guard hasMore, !isLoading, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let nextPage = currentPage + 1

        let filter: (String) -> Bool = { [weak blockedStore] title in
            blockedStore?.isBlocked(title) ?? false
        }

        do {
            let result = try await fetchPage(nextPage, isBlocked: filter)
            let merged = TopicPageMerger.merge(existing: topics, incoming: result.topics)
            let addedCount = merged.count - topics.count
            topics = merged
            currentPage = nextPage
            pagination = result.pagination
            hasMore = addedCount > 0 && result.pagination.hasNextPage
        } catch {
            self.error = error.localizedDescription
        }
    }

    func blockTopic(_ title: String) {
        blockedStore?.block(title)
        topics.removeAll { $0.title == title }
    }

    private func fetchPage(
        _ page: Int,
        isBlocked: @escaping (String) -> Bool
    ) async throws -> (topics: [Topic], pagination: Pagination) {
        switch listType {
        case .popular:
            return try await topicService.fetchPopularTopicsPaginated(page: page, isBlocked: isBlocked)
        case .today:
            return try await topicService.fetchTodayTopicsPaginated(page: page, isBlocked: isBlocked)
        case .todayInHistory:
            let topics = try await topicService.fetchFromEndpoint(.todayInHistory(year: year), isBlocked: isBlocked)
            return (topics, .empty)
        case .following:
            let topics = try await topicService.fetchFromEndpoint(.following, isBlocked: isBlocked)
            return (topics, .empty)
        case .latest:
            let topics = try await topicService.fetchFromEndpoint(.latest, isBlocked: isBlocked)
            return (topics, .empty)
        case .debe:
            let topics = try await topicService.fetchFromEndpoint(.debe, isBlocked: isBlocked)
            return (topics, .empty)
        case .kenar:
            let topics = try await topicService.fetchFromEndpoint(.kenar, isBlocked: isBlocked)
            return (topics, .empty)
        case .caylaklar:
            let topics = try await topicService.fetchFromEndpoint(.caylaklar, isBlocked: isBlocked)
            return (topics, .empty)
        case .cop:
            let topics = try await topicService.fetchFromEndpoint(.cop, isBlocked: isBlocked)
            return (topics, .empty)
        }
    }
}
