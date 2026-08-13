import Foundation

@MainActor
final class MessageThreadViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?

    private let messageService = MessageService()
    let threadLink: String
    let threadTitle: String

    init(link: String, title: String) {
        self.threadLink = link
        self.threadTitle = title
    }

    func loadMessages() async {
        isLoading = true
        error = nil

        do {
            messages = try await messageService.fetchThread(id: threadLink, participant: threadTitle)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
