import Foundation

enum EntryFilter: Equatable, Sendable {
    case none
    case dailyNice
    case eksiseyler
    case links
    case images
    case caylak
    case author(String)
    case search(String)
    case nice
    case niceWeek
    case niceMonth
    case nice3Months
    case niceAllTime

    var queryItems: [TopicQueryItem] {
        switch self {
        case .none:
            return []
        case .dailyNice, .nice:
            return [.init(name: "a", value: "dailynice")]
        case .eksiseyler:
            return [.init(name: "a", value: "eksiseyler")]
        case .links:
            return [
                .init(name: "a", value: "find"),
                .init(name: "keywords", value: "http://"),
            ]
        case .images:
            return [.init(name: "a", value: "gorseller")]
        case .caylak:
            return [.init(name: "a", value: "caylaklar")]
        case .author(let name):
            return [
                .init(name: "a", value: "search"),
                .init(name: "author", value: name),
            ]
        case .search(let keywords):
            return [
                .init(name: "a", value: "find"),
                .init(name: "keywords", value: keywords),
            ]
        case .niceWeek:
            return [.init(name: "a", value: "nice"), .init(name: "period", value: "week")]
        case .niceMonth:
            return [.init(name: "a", value: "nice"), .init(name: "period", value: "month")]
        case .nice3Months:
            return [.init(name: "a", value: "nice"), .init(name: "period", value: "3months")]
        case .niceAllTime:
            return [.init(name: "a", value: "nice"), .init(name: "period", value: "alltime")]
        }
    }

    var displayName: String {
        switch self {
        case .none: return "tumu"
        case .dailyNice: return "bugun"
        case .eksiseyler: return "eksi seyler'de"
        case .links: return "linkler"
        case .images: return "gorseller"
        case .caylak: return "caylaklar"
        case .author: return "benimkiler"
        case .search: return "baslikta ara"
        case .nice: return "son 24 saat"
        case .niceWeek: return "son 1 hafta"
        case .niceMonth: return "son 1 ay"
        case .nice3Months: return "son 3 ay"
        case .niceAllTime: return "tumu"
        }
    }
}
