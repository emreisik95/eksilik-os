import Foundation

struct EntryService {
    private let client = HTTPClient.shared

    func fetchEntries(link: String) async throws -> EntryPageParser.ParsedPage {
        let cleanLink = link.replacingOccurrences(of: "https://eksisozluk.com/", with: "")
            .replacingOccurrences(of: "https://eksisozluk.com", with: "")
        let html = try await client.fetchHTML(for: .topic(slug: cleanLink, page: nil))
        let username = await SessionManager.shared.username
        await SessionManager.shared.updateFromHTML(html)
        return EntryPageParser.parse(html: html, currentUsername: username)
    }

    func fetchEntriesAtPage(link: String, page: Int) async throws -> EntryPageParser.ParsedPage {
        let cleanLink = link.replacingOccurrences(of: "https://eksisozluk.com/", with: "")
            .replacingOccurrences(of: "https://eksisozluk.com", with: "")

        let separator = cleanLink.contains("?") ? "&" : "?"
        let fullLink = "\(cleanLink)\(separator)p=\(page)"
        let html = try await client.fetchHTML(for: .topic(slug: fullLink, page: nil))
        let username = await SessionManager.shared.username
        await SessionManager.shared.updateFromHTML(html)
        return EntryPageParser.parse(html: html, currentUsername: username)
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

    func deleteEntry(id: String) async throws {
        try await client.post(endpoint: .deleteEntry, body: ["Id": id])
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
