import Foundation

enum WebBootstrapPolicy {
    static func shouldComplete(
        statusCode: Int?,
        headers: [String: String],
        title: String,
        html: String
    ) -> Bool {
        guard let statusCode, (200...299).contains(statusCode) else {
            return false
        }

        guard !isChallenge(
            statusCode: statusCode,
            headers: headers,
            title: title,
            html: html
        ) else {
            return false
        }

        let normalizedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return !normalizedTitle.isEmpty && html.lowercased().contains("<html")
    }

    static func isChallenge(
        statusCode: Int?,
        headers: [String: String],
        title: String,
        html: String
    ) -> Bool {
        _ = statusCode

        let normalizedHeaders = headers.reduce(into: [String: String]()) { result, pair in
            result[pair.key.lowercased()] = pair.value.lowercased()
        }
        if normalizedHeaders["cf-mitigated"] == "challenge" {
            return true
        }

        let normalizedTitle = title
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let challengeTitles = [
            "lütfen bekleyiniz",
            "just a moment",
            "checking your browser",
            "attention required",
        ]
        if challengeTitles.contains(where: normalizedTitle.contains) {
            return true
        }

        let normalizedHTML = html.lowercased()
        let challengeMarkers = [
            "_cf_chl_opt",
            "/cdn-cgi/challenge-platform/",
            "cf-chl-",
        ]
        return challengeMarkers.contains(where: normalizedHTML.contains)
    }
}
