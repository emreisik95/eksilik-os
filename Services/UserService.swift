import Foundation

struct UserService {
    private let client = HTTPClient.shared

    func fetchProfile(username: String) async throws -> UserProfile {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let html = try await client.fetchHTML(for: .profile(username: encoded))
        await SessionManager.shared.updateFromHTML(html)
        return UserProfileParser.parse(html: html)
    }

    func fetchProfileEntries(username: String, filter: String) async throws -> [UserProfile.ProfileEntry] {
        let encoded = username.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? username
        let html = try await client.fetchHTML(for: .profileEntries(username: encoded, filter: filter))
        return UserProfileParser.parseProfileEntries(html: html)
    }

    func performAction(url: String) async throws {
        let html = try await client.fetchHTML(for: .topic(slug: url, page: nil))
        _ = html
    }
}
