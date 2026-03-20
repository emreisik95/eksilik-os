import Foundation

@MainActor
final class TopicListViewModel: ObservableObject {
    @Published var topics: [Topic] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var pagination: Pagination = .empty

    private let topicService = TopicService()
    private let blockedStore: BlockedTopicStore

    enum ListType: String {
        case popular, today, todayInHistory, following, latest, debe, kenar, caylaklar, cop
    }

    let listType: ListType
    private var currentPage = 1
    var year: Int?

    init(listType: ListType, blockedStore: BlockedTopicStore) {
        self.listType = listType
        self.blockedStore = blockedStore
    }

    func loadTopics() async {
        print("loadTopics called for \(listType)")
        isLoading = true
        error = nil
        currentPage = 1

        let filter: (String) -> Bool = { [blockedStore] title in
            blockedStore.isBlocked(title)
        }

        do {
            switch listType {
            case .popular:
                topics = try await topicService.fetchPopularTopics(isBlocked: filter)
            case .today:
                topics = try await topicService.fetchTodayTopics(page: 1, isBlocked: filter)
            case .todayInHistory:
                topics = try await topicService.fetchFromEndpoint(.todayInHistory(year: year), isBlocked: filter)
            case .following:
                topics = try await topicService.fetchFromEndpoint(.following, isBlocked: filter)
            case .latest:
                topics = try await topicService.fetchFromEndpoint(.latest, isBlocked: filter)
            case .debe:
                topics = try await topicService.fetchFromEndpoint(.debe, isBlocked: filter)
            case .kenar:
                topics = try await topicService.fetchFromEndpoint(.kenar, isBlocked: filter)
            case .caylaklar:
                topics = try await topicService.fetchFromEndpoint(.caylaklar, isBlocked: filter)
            case .cop:
                topics = try await topicService.fetchFromEndpoint(.cop, isBlocked: filter)
            }
        } catch {
            print("loadTopics error: \(error)")
            self.error = error.localizedDescription
        }

        isLoading = false
        print("loadTopics done, \(topics.count) topics, error=\(self.error ?? "nil")")
    }

    func loadMore() async {
        guard !isLoading else { return }
        currentPage += 1

        let filter: (String) -> Bool = { [blockedStore] title in
            blockedStore.isBlocked(title)
        }

        do {
            let newTopics: [Topic]
            switch listType {
            case .popular:
                newTopics = try await topicService.fetchPopularTopics(isBlocked: filter)
            case .today:
                newTopics = try await topicService.fetchTodayTopics(page: currentPage, isBlocked: filter)
            case .todayInHistory:
                newTopics = try await topicService.fetchFromEndpoint(.todayInHistory(year: year), isBlocked: filter)
            case .following:
                newTopics = try await topicService.fetchFromEndpoint(.following, isBlocked: filter)
            case .latest:
                newTopics = try await topicService.fetchFromEndpoint(.latest, isBlocked: filter)
            case .debe:
                newTopics = try await topicService.fetchFromEndpoint(.debe, isBlocked: filter)
            case .kenar:
                return
            case .caylaklar:
                return
            case .cop:
                return
            }
            topics.append(contentsOf: newTopics)
        } catch {
            currentPage -= 1
        }
    }

    func blockTopic(_ title: String) {
        blockedStore.block(title)
        topics.removeAll { $0.title == title }
    }
}
