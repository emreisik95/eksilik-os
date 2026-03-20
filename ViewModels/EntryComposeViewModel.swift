import Foundation

@MainActor
final class EntryComposeViewModel: ObservableObject {
    @Published var content = ""
    @Published var topicTitle = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var isSubmitted = false

    private let entryService = EntryService()
    private var token = ""
    private var formTitle = ""
    private var formId = ""
    private var returnURL = ""

    let topicLink: String

    init(topicLink: String) {
        self.topicLink = topicLink
    }

    func loadForm() async {
        isLoading = true
        do {
            if let fields = try await entryService.fetchEntryFormFields(link: topicLink) {
                token = fields.token
                formTitle = fields.title
                formId = fields.id
                returnURL = fields.returnURL
                topicTitle = fields.title
            }
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func submit() async {
        guard !content.isEmpty else {
            error = "Entry cannot be empty"
            return
        }

        isLoading = true
        do {
            try await entryService.createEntry(
                content: content,
                title: formTitle,
                returnURL: returnURL,
                id: formId,
                token: token
            )
            isSubmitted = true
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }

    func insertBkz(_ text: String) {
        content += "(bkz: \(text))"
    }

    func insertHede(_ text: String) {
        content += "`\(text)`"
    }

    func insertSpoiler(_ text: String) {
        content += "--- `spoiler` ---\n\(text)\n--- `spoiler` ---"
    }

    func insertLink(_ url: String) {
        content += url
    }
}
