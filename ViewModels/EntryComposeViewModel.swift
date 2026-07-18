import Foundation

@MainActor
final class EntryComposeViewModel: ObservableObject {
    @Published var content: String {
        didSet {
            draftStore.save(content, for: topicLink)
            lastDraftSavedAt = content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? nil
                : Date()
        }
    }
    @Published var topicTitle = ""
    @Published var isLoadingForm = false
    @Published var isSubmitting = false
    @Published var error: String?
    @Published var isSubmitted = false
    @Published private(set) var isFormReady = false
    @Published private(set) var lastDraftSavedAt: Date?

    private let entryService = EntryService()
    private let draftStore: EntryDraftStore
    private var token = ""
    private var formTitle = ""
    private var formId = ""
    private var returnURL = ""

    let topicLink: String

    var canSubmit: Bool {
        isFormReady
            && !isSubmitting
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(topicLink: String, draftStore: EntryDraftStore = .shared) {
        self.topicLink = topicLink
        self.draftStore = draftStore
        let draft = draftStore.load(for: topicLink) ?? ""
        content = draft
        lastDraftSavedAt = draft.isEmpty ? nil : Date()
    }

    func loadForm() async {
        guard !isFormReady, !isLoadingForm else { return }
        isLoadingForm = true
        error = nil
        defer { isLoadingForm = false }

        do {
            guard let fields = try await entryService.fetchEntryFormFields(link: topicLink) else {
                error = "entry formu yüklenemedi"
                return
            }
            token = fields.token
            formTitle = fields.title
            formId = fields.id
            returnURL = fields.returnURL
            topicTitle = fields.title
            isFormReady = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func submit() async {
        guard !isSubmitting else { return }
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            error = "entry boş olamaz"
            return
        }
        guard isFormReady else {
            error = "entry formu henüz hazır değil"
            return
        }

        isSubmitting = true
        error = nil
        defer { isSubmitting = false }

        do {
            try await entryService.createEntry(
                content: content,
                title: formTitle,
                returnURL: returnURL,
                id: formId,
                token: token
            )
            draftStore.clear(for: topicLink)
            isSubmitted = true
        } catch {
            self.error = error.localizedDescription
        }
    }

    func insert(_ replacement: String, at selection: NSRange) -> NSRange {
        let mutation = EntryFormatting.insert(replacement, into: content, selection: selection)
        content = mutation.text
        return mutation.selection
    }
}
