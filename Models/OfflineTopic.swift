import Foundation

enum OfflineContentMode: String, Codable, CaseIterable, Sendable {
    case normal
    case sukela

    var title: String {
        switch self {
        case .normal: return "normal"
        case .sukela: return "şükela"
        }
    }
}

enum OfflinePageLimit: String, Codable, CaseIterable, Sendable {
    case fivePages
    case tenPages
    case allPages

    var title: String {
        switch self {
        case .fivePages: return "ilk 5 sayfa"
        case .tenPages: return "ilk 10 sayfa"
        case .allPages: return "tüm sayfalar"
        }
    }
}

enum OfflineDownloadStatus: String, Codable, Sendable {
    case queued
    case downloading
    case completed
    case failed
    case cancelled

    var isActive: Bool {
        self == .queued || self == .downloading
    }
}

struct OfflineTopic: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var title: String
    var request: TopicRequest
    var contentMode: OfflineContentMode
    var pageLimit: OfflinePageLimit
    var totalPages: Int
    var completedPages: [Int]
    var createdAt: Date
    var updatedAt: Date
    var status: OfflineDownloadStatus
    var errorMessage: String?

    init(
        title: String,
        request: TopicRequest,
        contentMode: OfflineContentMode,
        pageLimit: OfflinePageLimit,
        totalPages: Int
    ) {
        self.id = OfflineIdentifier.value(for: "\(request.settingPage(nil).pathAndQuery)|\(contentMode.rawValue)")
        self.title = title
        self.request = request.settingPage(nil)
        self.contentMode = contentMode
        self.pageLimit = pageLimit
        self.totalPages = max(1, totalPages)
        self.completedPages = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.status = .queued
        self.errorMessage = nil
    }

    var plannedPages: [Int] {
        OfflineDownloadPlanner.pages(for: pageLimit, totalPages: totalPages)
    }

    var progress: Double {
        guard !plannedPages.isEmpty else { return 0 }
        let completed = Set(completedPages).intersection(plannedPages)
        return min(Double(completed.count) / Double(plannedPages.count), 1)
    }

    var isReadable: Bool { !completedPages.isEmpty }
}

struct OfflineTopicPage: Codable, Hashable, Sendable {
    let topicID: String
    let pageNumber: Int
    var title: String
    var entries: [OfflineEntry]
    var downloadedAt: Date

    init(topicID: String, pageNumber: Int, title: String, entries: [OfflineEntry], downloadedAt: Date = Date()) {
        self.topicID = topicID
        self.pageNumber = max(1, pageNumber)
        self.title = title
        self.entries = OfflineEntry.orderedUnique(entries)
        self.downloadedAt = downloadedAt
    }
}

struct OfflineEntry: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let contentHTML: String
    let authorNick: String
    let authorID: String
    let authorAvatarURL: String?
    let date: String
    let favoriteCount: Int
    let imageURLs: [String]

    init(
        id: String,
        contentHTML: String,
        authorNick: String,
        authorID: String,
        authorAvatarURL: String?,
        date: String,
        favoriteCount: Int,
        imageURLs: [String]
    ) {
        self.id = id
        self.contentHTML = contentHTML
        self.authorNick = authorNick
        self.authorID = authorID
        self.authorAvatarURL = authorAvatarURL
        self.date = date
        self.favoriteCount = favoriteCount
        self.imageURLs = ImageURLNormalizer.normalizeStrings(imageURLs)
    }

    init(entry: Entry) {
        self.init(
            id: entry.id,
            contentHTML: entry.contentHTML,
            authorNick: entry.author.nick,
            authorID: entry.authorId,
            authorAvatarURL: entry.author.avatarURL,
            date: entry.date,
            favoriteCount: entry.favoriteCount,
            imageURLs: entry.imageURLs
        )
    }

    static func orderedUnique(_ entries: [OfflineEntry]) -> [OfflineEntry] {
        var seen = Set<String>()
        return entries.filter { seen.insert($0.id).inserted }
    }
}

enum OfflineDownloadPlanner {
    static func pages(for limit: OfflinePageLimit, totalPages: Int) -> [Int] {
        let available = max(1, totalPages)
        let count: Int
        switch limit {
        case .fivePages: count = min(5, available)
        case .tenPages: count = min(10, available)
        case .allPages: count = available
        }
        return Array(1...count)
    }
}

enum OfflineMediaKey {
    static func filename(for rawURL: String) -> String {
        let normalized = ImageURLNormalizer.normalize(rawURL)
        let value = normalized?.absoluteString ?? rawURL
        let pathExtension = normalized?.pathExtension.lowercased() ?? ""
        let safeExtension = pathExtension.range(of: #"^[a-z0-9]{1,8}$"#, options: .regularExpression) != nil
            ? pathExtension
            : "bin"
        return "\(OfflineIdentifier.value(for: value)).\(safeExtension)"
    }
}

private enum OfflineIdentifier {
    static func value(for value: String) -> String {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 1_099_511_628_211
        }
        return String(format: "%016llx", hash)
    }
}
