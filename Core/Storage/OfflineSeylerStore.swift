import Foundation

enum OfflineSeylerStoreError: LocalizedError {
    case missingArticle
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .missingArticle: return "çevrimdışı Şeyler yazısı bulunamadı"
        case .invalidResponse: return "Şeyler görseli indirilemedi"
        }
    }
}

actor OfflineSeylerStore {
    static let shared = OfflineSeylerStore()

    let rootURL: URL
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(rootURL: URL? = nil, fileManager: FileManager = .default) {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            let applicationSupport = fileManager.urls(
                for: .applicationSupportDirectory,
                in: .userDomainMask
            ).first ?? fileManager.temporaryDirectory
            self.rootURL = applicationSupport
                .appendingPathComponent("Eksilik", isDirectory: true)
                .appendingPathComponent("OfflineSeyler", isDirectory: true)
        }

        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    @discardableResult
    func saveArticle(_ article: SeylerArticle) throws -> OfflineSeylerArticle {
        let saved = OfflineSeylerArticle(article: article)
        try ensureDirectory(articleDirectory(id: saved.id))
        try ensureDirectory(mediaDirectory(id: saved.id))
        try write(saved, to: manifestURL(id: saved.id))
        return saved
    }

    func saveArticleAndMedia(
        _ article: SeylerArticle,
        session: URLSession = .shared
    ) async throws -> OfflineSeylerArticle {
        let saved = try saveArticle(article)
        for sourceURL in article.imageURLs {
            do {
                var request = URLRequest(url: sourceURL)
                request.timeoutInterval = 30
                request.setValue(
                    "image/avif,image/webp,image/apng,image/*,*/*;q=0.8",
                    forHTTPHeaderField: "Accept"
                )
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse,
                      (200...299).contains(http.statusCode),
                      !data.isEmpty else {
                    throw OfflineSeylerStoreError.invalidResponse
                }
                _ = try saveMedia(data, articleID: saved.id, sourceURL: sourceURL)
            } catch {
                // Text remains fully readable offline when an individual remote
                // image is unavailable. Other images continue downloading.
                continue
            }
        }
        return saved
    }

    func loadArticle(sourceURL: URL) throws -> OfflineSeylerArticle {
        try loadArticle(id: OfflineIdentifier.value(for: sourceURL.absoluteString))
    }

    func loadArticle(id: String) throws -> OfflineSeylerArticle {
        let url = manifestURL(id: id)
        guard fileManager.fileExists(atPath: url.path) else {
            throw OfflineSeylerStoreError.missingArticle
        }
        return try read(OfflineSeylerArticle.self, from: url)
    }

    func listArticles() throws -> [OfflineSeylerArticle] {
        try ensureDirectory(rootURL)
        let directories = try fileManager.contentsOfDirectory(
            at: rootURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )
        return directories.compactMap { directory in
            try? read(
                OfflineSeylerArticle.self,
                from: directory.appendingPathComponent("manifest.json")
            )
        }
        .sorted { $0.savedAt > $1.savedAt }
    }

    func contains(sourceURL: URL) -> Bool {
        let id = OfflineIdentifier.value(for: sourceURL.absoluteString)
        return fileManager.fileExists(atPath: manifestURL(id: id).path)
    }

    @discardableResult
    func saveMedia(_ data: Data, articleID: String, sourceURL: URL) throws -> URL {
        let destination = mediaDirectory(id: articleID)
            .appendingPathComponent(OfflineMediaKey.filename(for: sourceURL.absoluteString))
        try ensureDirectory(destination.deletingLastPathComponent())
        try data.write(to: destination, options: [.atomic])
        return destination
    }

    func localMediaURL(articleID: String, sourceURL: URL) -> URL? {
        let url = mediaDirectory(id: articleID)
            .appendingPathComponent(OfflineMediaKey.filename(for: sourceURL.absoluteString))
        return fileManager.fileExists(atPath: url.path) ? url : nil
    }

    func storageSize(articleID: String) -> Int64 {
        directorySize(at: articleDirectory(id: articleID))
    }

    func deleteArticle(id: String) throws {
        let directory = articleDirectory(id: id)
        if fileManager.fileExists(atPath: directory.path) {
            try fileManager.removeItem(at: directory)
        }
    }

    private func articleDirectory(id: String) -> URL {
        rootURL.appendingPathComponent(id, isDirectory: true)
    }

    private func mediaDirectory(id: String) -> URL {
        articleDirectory(id: id).appendingPathComponent("media", isDirectory: true)
    }

    private func manifestURL(id: String) -> URL {
        articleDirectory(id: id).appendingPathComponent("manifest.json")
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

    private func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey]
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(
                forKeys: [.fileSizeKey, .isRegularFileKey]
            ), values.isRegularFile == true else { continue }
            total += Int64(values.fileSize ?? 0)
        }
        return total
    }
}
