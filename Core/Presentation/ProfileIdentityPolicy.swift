import Foundation

enum ProfileIdentityPolicy {
    static func matchesAuthenticatedUser(
        authenticatedUsername: String?,
        profileUsername: String
    ) -> Bool {
        guard let authenticatedUsername else { return false }
        let locale = Locale(identifier: "tr_TR")
        let authenticated = authenticatedUsername
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: locale)
        let profile = profileUsername
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(with: locale)
        return !authenticated.isEmpty && authenticated == profile
    }
}
