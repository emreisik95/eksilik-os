import Foundation

enum OfflineTopicStoreError: LocalizedError {
    case missingTopic
    case corruptManifest

    var errorDescription: String? {
        switch self {
        case .missingTopic: return "çevrimdışı başlık bulunamadı"
        case .corruptManifest: return "çevrimdışı başlık verisi bozuk"
        }
    }
}

actor OfflineTopicStore {
    static let shared = OfflineTopicStore()

    let rootURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
                ?? fileManager.temporaryDirectory
            self.rootURL = applicationSupport
                .appendingPathComponent("Eksilik", isDirectory: true)
                .appendingPathComponent("OfflineTopics", isDirectory: true)
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func saveTopic(_ topic: OfflineTopic) throws {
        try ensureDirectory(topicDirectory(id: topic.id))
        try ensureDirectory(pagesDirectory(id: topic.id))
        try ensureDirectory(mediaDirectory(id: topic.id))
        try write(topic, to: manifestURL(id: topic.id))
    }

    func loadTopic(id: String) throws -> OfflineTopic {
        let url = manifestURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else {
            throw OfflineTopicStoreError.missingTopic
        }
        do {
            return try read(OfflineTopic.self, from: url)
        } catch {
            try? quarantineManifest(at: url)
            throw OfflineTopicStoreError.corruptManifest
        }
    }

    func listTopics() throws -> [OfflineTopic] {
        try ensureDirectory(rootURL)
        let directories = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        var topics: [OfflineTopic] = []
        for directory in directories {
            let manifest = directory.appendingPathComponent("manifest.json")
            guard fileManager.fileExists(atPath: manifest.path) else { continue }
            do {
                topics.append(try read(OfflineTopic.self, from: manifest))
            } catch {
                try? quarantineManifest(at: manifest)
            }
        }
        return topics.sorted { $0.updatedAt > $1.updatedAt }
    }

    func savePage(_ page: OfflineTopicPage) throws {
        var normalized = page
        normalized.entries = OfflineEntry.orderedUnique(page.entries)
        try ensureDirectory(pagesDirectory(id: page.topicID))
        try write(normalized, to: pageURL(topicID: page.topicID, pageNumber: page.pageNumber))

        var topic = try loadTopic(id: page.topicID)
        if !topic.completedPages.contains(page.pageNumber) {
            topic.completedPages.append(page.pageNumber)
            topic.completedPages.sort()
        }
        topic.updatedAt = Date()
        topic.errorMessage = nil
        topic.status = Set(topic.completedPages).isSuperset(of: topic.plannedPages)
            ? .completed
            : .downloading
        try saveTopic(topic)
    }

    func loadPage(topicID: String, pageNumber: Int) throws -> OfflineTopicPage {
        try read(OfflineTopicPage.self, from: pageURL(topicID: topicID, pageNumber: pageNumber))
    }

    func loadAllEntries(topicID: String) throws -> [OfflineEntry] {
        let topic = try loadTopic(id: topicID)
        let entries = try topic.completedPages.sorted().flatMap {
            try loadPage(topicID: topicID, pageNumber: $0).entries
        }
        return OfflineEntry.orderedUnique(entries)
    }

    func updateStatus(id: String, status: OfflineDownloadStatus, errorMessage: String? = nil) throws {
        var topic = try loadTopic(id: id)
        topic.status = status
        topic.errorMessage = errorMessage
        topic.updatedAt = Date()
        try saveTopic(topic)
    }

    func mediaDestinationURL(topicID: String, sourceURL: String) throws -> URL {
        let directory = mediaDirectory(id: topicID)
        try ensureDirectory(directory)
        return directory.appendingPathComponent(OfflineMediaKey.filename(for: sourceURL))
    }

    func saveMedia(from temporaryURL: URL, topicID: String, sourceURL: String) throws -> URL {
        let destination = try mediaDestinationURL(topicID: topicID, sourceURL: sourceURL)
        if fileManager.fileExists(atPath: destination.path) {
            try fileManager.removeItem(at: destination)
        }
        try fileManager.moveItem(at: temporaryURL, to: destination)
        return destination
    }

    func localMediaURL(topicID: String, sourceURL: String) -> URL? {
        let url = mediaDirectory(id: topicID)
            .appendingPathComponent(OfflineMediaKey.filename(for: sourceURL))
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func storageSize(topicID: String) -> Int64 {
        directorySize(at: topicDirectory(id: topicID))
    }

    func deleteTopic(id: String) throws {
        let directory = topicDirectory(id: id)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
    }

    private func topicDirectory(id: String) -> URL {
        rootURL.appendingPathComponent(id, isDirectory: true)
    }

    private func pagesDirectory(id: String) -> URL {
        topicDirectory(id: id).appendingPathComponent("pages", isDirectory: true)
    }

    private func mediaDirectory(id: String) -> URL {
        topicDirectory(id: id).appendingPathComponent("media", isDirectory: true)
    }

    private func manifestURL(id: String) -> URL {
        topicDirectory(id: id).appendingPathComponent("manifest.json")
    }

    private func pageURL(topicID: String, pageNumber: Int) -> URL {
        pagesDirectory(id: topicID)
            .appendingPathComponent(String(format: "page-%04d.json", max(1, pageNumber)))
    }

    private func ensureDirectory(_ url: URL) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        let data = try encoder.encode(value)
        try ensureDirectory(url.deletingLastPathComponent())
        try data.write(to: url, options: [.atomic])
    }

    private func read<T: Decodable>(_ type: T.Type, from url: URL) throws -> T {
        try decoder.decode(type, from: Data(contentsOf: url))
    }

    private func quarantineManifest(at url: URL) throws {
        guard fileManager.fileExists(atPath: url.path) else { return }
        let quarantine = url.deletingLastPathComponent()
            .appendingPathComponent("manifest-corrupt-\(Int(Date().timeIntervalSince1970)).json")
        if fileManager.fileExists(atPath: quarantine.path) {
            try fileManager.removeItem(at: quarantine)
        }
        try fileManager.moveItem(at: url, to: quarantine)
    }

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey]),
                  values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
