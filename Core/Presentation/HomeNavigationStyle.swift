import Foundation

enum HomeNavigationStyle: String, CaseIterable, Codable, Identifiable, Sendable {
    case classicBottom
    case topRail
    case floatingDock
    case sidebar
    case menuLauncher

    var id: String { rawValue }

    var name: String {
        switch self {
        case .classicBottom: return "klasik alt bar"
        case .topRail: return "üst şerit"
        case .floatingDock: return "yüzen dock"
        case .sidebar: return "yan panel"
        case .menuLauncher: return "menü başlatıcı"
        }
    }

    var summary: String {
        switch self {
        case .classicBottom: return "tanıdık, tam genişlikte sekmeler"
        case .topRail: return "içeriğin üstünde hızlı geçiş şeridi"
        case .floatingDock: return "ikon ağırlıklı, tek elle erişilen dock"
        case .sidebar: return "menü düğmesiyle açılan geniş yan panel"
        case .menuLauncher: return "kalabalığı gizleyen kompakt açılır menü"
        }
    }

    var systemImage: String {
        switch self {
        case .classicBottom: return "rectangle.bottomthird.inset.filled"
        case .topRail: return "rectangle.topthird.inset.filled"
        case .floatingDock: return "capsule"
        case .sidebar: return "sidebar.left"
        case .menuLauncher: return "square.grid.2x2"
        }
    }

    static func resolve(storedValue: String?, legacyPosition: String?) -> HomeNavigationStyle {
        if let storedValue {
            return HomeNavigationStyle(rawValue: storedValue) ?? .floatingDock
        }

        switch legacyPosition {
        case "bottom": return .classicBottom
        case "top": return .topRail
        default: return .floatingDock
        }
    }
}

struct HomeTabDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let systemImage: String
    let requiresLogin: Bool

    static let all: [HomeTabDefinition] = [
        HomeTabDefinition(id: "popular", name: "gündem", systemImage: "flame", requiresLogin: false),
        HomeTabDefinition(id: "today", name: "bugün", systemImage: "sun.max", requiresLogin: false),
        HomeTabDefinition(id: "debe", name: "debe", systemImage: "crown", requiresLogin: false),
        HomeTabDefinition(id: "todayInHistory", name: "tarihte bugün", systemImage: "calendar", requiresLogin: false),
        HomeTabDefinition(id: "latest", name: "son", systemImage: "clock", requiresLogin: true),
        HomeTabDefinition(id: "following", name: "takip", systemImage: "bell", requiresLogin: true),
        HomeTabDefinition(id: "kenar", name: "kenar", systemImage: "bookmark", requiresLogin: true),
        HomeTabDefinition(id: "caylaklar", name: "çaylaklar", systemImage: "leaf", requiresLogin: false),
        HomeTabDefinition(id: "cop", name: "çöp", systemImage: "trash", requiresLogin: true),
    ]
}

enum HomeTabCatalog {
    static let defaultOrder = HomeTabDefinition.all.map(\.id)

    static func normalizedOrder(_ storedOrder: [String]) -> [String] {
        let known = Set(defaultOrder)
        var seen = Set<String>()
        var result: [String] = []

        for id in storedOrder + defaultOrder where known.contains(id) && seen.insert(id).inserted {
            result.append(id)
        }
        return result
    }

    static func moving(
        _ order: [String],
        fromOffsets source: IndexSet,
        toOffset destination: Int
    ) -> [String] {
        var result = normalizedOrder(order)
        let validOffsets = source.filter { result.indices.contains($0) }.sorted()
        guard !validOffsets.isEmpty else { return result }

        let movingItems = validOffsets.map { result[$0] }
        for index in validOffsets.reversed() {
            result.remove(at: index)
        }

        let removedBeforeDestination = validOffsets.filter { $0 < destination }.count
        let insertionIndex = max(0, min(result.count, destination - removedBeforeDestination))
        result.insert(contentsOf: movingItems, at: insertionIndex)
        return normalizedOrder(result)
    }

    static func availableTabs(
        order: [String],
        visible: [String],
        isLoggedIn: Bool
    ) -> [HomeTabDefinition] {
        let definitions = Dictionary(uniqueKeysWithValues: HomeTabDefinition.all.map { ($0.id, $0) })
        let visibleIDs = visible.isEmpty ? Set(defaultOrder) : Set(visible)
        let available = normalizedOrder(order).compactMap { definitions[$0] }.filter { tab in
            visibleIDs.contains(tab.id) && (isLoggedIn || !tab.requiresLogin)
        }

        if !available.isEmpty {
            return available
        }
        return HomeTabDefinition.all.filter { $0.id == "popular" }
    }
}

enum HomeNavigationPolicy {
    static func step(horizontal: Double, vertical: Double) -> Int? {
        guard abs(horizontal) >= 64, abs(horizontal) > abs(vertical) * 1.35 else {
            return nil
        }
        return horizontal < 0 ? 1 : -1
    }

    static func adjacentTabID(in ids: [String], selected: String, step: Int) -> String {
        guard !ids.isEmpty else { return selected }
        guard let currentIndex = ids.firstIndex(of: selected) else { return ids[0] }
        let targetIndex = max(0, min(ids.count - 1, currentIndex + step))
        return ids[targetIndex]
    }
}
