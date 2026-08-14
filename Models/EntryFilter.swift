import Foundation

enum EntryFilter: Equatable, Hashable, Sendable {
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

    static func inferred(from queryItems: [TopicQueryItem]) -> EntryFilter {
        let items = Dictionary(
            queryItems.map { ($0.name.lowercased(), $0.value ?? "") },
            uniquingKeysWith: { _, latest in latest }
        )
        let action = items["a"]?.lowercased()

        switch action {
        case "dailynice":
            return .dailyNice
        case "eksiseyler":
            return .eksiseyler
        case "gorseller":
            return .images
        case "caylaklar":
            return .caylak
        case "search":
            guard let author = items["author"], !author.isEmpty else { return .none }
            return .author(author)
        case "find":
            guard let keywords = items["keywords"], !keywords.isEmpty else { return .none }
            return keywords == "http://" ? .links : .search(keywords)
        case "nice":
            return inferredNiceFilter(period: items["period"])
        default:
            return .none
        }
    }

    private static func inferredNiceFilter(period: String?) -> EntryFilter {
        switch period?.lowercased() {
        case "week": return .niceWeek
        case "month": return .niceMonth
        case "3months": return .nice3Months
        case "alltime": return .niceAllTime
        default: return .nice
        }
    }
}

enum EntryFilterTransitionPolicy {
    static func shouldResetContent(from current: EntryFilter, to next: EntryFilter) -> Bool {
        current != next
    }
}
