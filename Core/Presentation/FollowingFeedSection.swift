enum FollowingFeedSection: String, CaseIterable, Identifiable, Sendable {
    case written
    case favorited

    var id: String { rawValue }

    var title: String {
        switch self {
        case .written: return "yazdıkları"
        case .favorited: return "favladıkları"
        }
    }

    var emptyMessage: String {
        switch self {
        case .written: return "yok bişii pek"
        case .favorited: return L10n.Common.noTopics
        }
    }

    func endpoint(page: Int) -> EksiEndpoint {
        switch self {
        case .written:
            return .followingPage(page: max(1, page))
        case .favorited:
            return .followingFavorites(page: max(1, page))
        }
    }
}
