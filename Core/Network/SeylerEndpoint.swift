import Foundation

enum SeylerCategory: String, CaseIterable, Identifiable, Sendable {
    case latest
    case culture
    case science
    case entertainment
    case life
    case sports
    case news

    var id: String { rawValue }

    var title: String {
        switch self {
        case .latest: return "yeni"
        case .culture: return "kültür"
        case .science: return "bilim"
        case .entertainment: return "eğlence"
        case .life: return "yaşam"
        case .sports: return "spor"
        case .news: return "haber"
        }
    }

    var path: String {
        switch self {
        case .latest: return "/"
        case .culture: return "/kategori/kultur"
        case .science: return "/kategori/bilim"
        case .entertainment: return "/kategori/eglence"
        case .life: return "/kategori/yasam"
        case .sports: return "/kategori/spor"
        case .news: return "/kategori/haber"
        }
    }

    var systemImage: String {
        switch self {
        case .latest: return "sparkles"
        case .culture: return "theatermasks"
        case .science: return "atom"
        case .entertainment: return "party.popper"
        case .life: return "heart"
        case .sports: return "sportscourt"
        case .news: return "newspaper"
        }
    }
}

enum SeylerEndpoint {
    static let baseURL = URL(string: "https://eksiseyler.com")!

    static func url(for category: SeylerCategory) -> URL {
        URL(string: category.path, relativeTo: baseURL)!.absoluteURL
    }

    static func articleURL(from value: String) -> URL? {
        guard let url = URL(string: value, relativeTo: baseURL)?.absoluteURL,
              let scheme = url.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = url.host?.lowercased(),
              host == "eksiseyler.com" || host == "www.eksiseyler.com" else {
            return nil
        }

        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard !path.isEmpty,
              !path.hasPrefix("kategori/"),
              !path.hasPrefix("kanal/"),
              !path.hasPrefix("public/") else {
            return nil
        }

        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        components?.host = "eksiseyler.com"
        components?.query = nil
        components?.fragment = nil
        return components?.url
    }
}
