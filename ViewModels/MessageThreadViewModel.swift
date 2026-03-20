import Foundation

@MainActor
final class MessageThreadViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var error: String?

    private let client = HTTPClient.shared
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
            let html = try await client.fetchHTML(for: .messageThread(id: threadLink))
            messages = MessageContentParser.parse(html: html)
        } catch {
            self.error = error.localizedDescription
        }

        isLoading = false
    }
}
