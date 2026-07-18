import Foundation

struct EntryService {
    private let client = HTTPClient.shared

    func fetchEntries(request: TopicRequest) async throws -> EntryPageParser.ParsedPage {
        let html = try await client.fetchHTML(for: .topic(slug: request.pathAndQuery, page: nil))
        let username = await SessionManager.shared.username
        await SessionManager.shared.updateFromHTML(html)
        return EntryPageParser.parse(html: html, currentUsername: username)
    }

    func fetchEntriesAtPage(request: TopicRequest, page: Int) async throws -> EntryPageParser.ParsedPage {
        try await fetchEntries(request: request.settingPage(page))
    }

    func favorite(entryId: String) async throws {
        try await client.post(endpoint: .favoriteEntry, body: ["entryId": entryId])
    }

    func unfavorite(entryId: String) async throws {
        try await client.post(endpoint: .unfavoriteEntry, body: ["entryId": entryId])
    }

    func vote(entryId: String, rate: Int) async throws {
        try await client.post(endpoint: .voteEntry, body: ["Id": entryId, "rate": "\(rate)"])
    }

    func removeVote(entryId: String, rate: Int) async throws {
        try await client.post(endpoint: .removeVote, body: ["Id": entryId, "rate": "\(rate)"])
    }

    func blockUser(authorId: String) async throws {
        try await client.post(
            endpoint: .blockUser,
            body: ["Id": authorId, "r": "m"]
        )
    }

    func deleteEntry(id: String) async throws {
        try await client.post(endpoint: .deleteEntry, body: ["Id": id])
    }

    func trackTopic(id: String) async throws {
        try await client.post(endpoint: .trackTopic(id: id), body: [:])
    }

    func untrackTopic(id: String) async throws {
        try await client.post(endpoint: .untrackTopic(id: id), body: [:])
    }

    func createEntry(content: String, title: String, returnURL: String, id: String, token: String) async throws {
        try await client.post(
            endpoint: .createEntry,
            body: [
                "Content": content,
                "Title": title,
                "ReturnUrl": returnURL,
                "Id": id
            ],
            csrfToken: token
        )
    }

    func fetchEntryFormFields(link: String) async throws -> (token: String, title: String, id: String, returnURL: String)? {
        let html = try await client.fetchHTML(for: .topic(slug: link, page: nil))
        return AuthParser.parseEntryFormFields(html: html)
    }
}
