import Foundation

@MainActor
final class MessageListViewModel: ObservableObject {
    @Published var threads: [MessageThread] = []
    @Published var pagination: Pagination = .empty
    @Published var isLoading = false
    @Published var error: String?

    private let messageService = MessageService()

    func loadMessages(page: Int? = nil) async {
        isLoading = true
        error = nil

        do {
            let result = try await messageService.fetchMessages(page: page)
            threads = result.threads
            pagination = result.pagination
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
