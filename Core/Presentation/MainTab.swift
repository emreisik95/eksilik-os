import Foundation

enum MainTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case search
    case events
    case profile
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "anasayfa"
        case .search: return "ara"
        case .events: return "olay"
        case .profile: return "profil"
        case .settings: return "ayarlar"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house"
        case .search: return "magnifyingglass"
        case .events: return "bolt"
        case .profile: return "person"
        case .settings: return "gearshape"
        }
    }
}
