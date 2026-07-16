import Foundation

extension Notification.Name {
    static let offlineTopicsDidChange = Notification.Name("offlineTopicsDidChange")
}

private struct OfflineTransferDescriptor: Codable {
    enum Kind: String, Codable {
        case page
        case media
    }

    let kind: Kind
    let topicID: String
    let pageNumber: Int?
    let sourceURL: String?
    let retryCount: Int

    var key: String {
        switch kind {
        case .page: return "\(topicID)|page|\(pageNumber ?? 0)"
        case .media: return "\(topicID)|media|\(sourceURL ?? "")"
        }
    }

    func retrying() -> OfflineTransferDescriptor {
        OfflineTransferDescriptor(
            kind: kind,
            topicID: topicID,
            pageNumber: pageNumber,
            sourceURL: sourceURL,
            retryCount: retryCount + 1
        )
    }
}

final class OfflineDownloadManager: NSObject, URLSessionDownloadDelegate, URLSessionDelegate, @unchecked Sendable {
    static let shared = OfflineDownloadManager()
    static let sessionIdentifier = "com.eksilik.app.offline-downloads"

    private let store = OfflineTopicStore.shared
    private let stateQueue = DispatchQueue(label: "com.eksilik.offline-download-state")
    private var enqueuedKeys = Set<String>()
    private var backgroundCompletionHandler: (() -> Void)?
    private lazy var session: URLSession = makeSession()

    private override init() {
        super.init()
    }

    func activate() {
        session.getAllTasks { [weak self] tasks in
            guard let self else { return }
            let keys = tasks.compactMap { self.descriptor(for: $0)?.key }
            self.stateQueue.async {
                self.enqueuedKeys.formUnion(keys)
            }
        }
    }

    func reconnect(completionHandler: @escaping () -> Void) {
        stateQueue.async {
            self.backgroundCompletionHandler = completionHandler
        }
        activate()
    }

    func startDownload(
        title: String,
        request: TopicRequest,
        contentMode: OfflineContentMode,
        pageLimit: OfflinePageLimit,
        totalPages: Int
    ) async throws -> OfflineTopic {
        let cleanRequest = request
            .settingPage(nil)
            .applying(filter: contentMode == .sukela ? .niceAllTime : .none)
        let topic = OfflineTopic(
            title: title,
            request: cleanRequest,
            contentMode: contentMode,
            pageLimit: pageLimit,
            totalPages: totalPages
        )

        await cancelTasks(topicID: topic.id)
        try await store.saveTopic(topic)
        try await store.updateStatus(id: topic.id, status: .downloading)
        for page in topic.plannedPages {
            enqueuePage(topic: topic, page: page, retryCount: 0)
        }
        postChange()
        return try await store.loadTopic(id: topic.id)
    }

    func retry(topicID: String) async throws {
        let topic = try await store.loadTopic(id: topicID)
        try await store.updateStatus(id: topicID, status: .downloading)
        let completed = Set(topic.completedPages)
        for page in topic.plannedPages where !completed.contains(page) {
            enqueuePage(topic: topic, page: page, retryCount: 0)
        }
        postChange()
    }

    func cancel(topicID: String) async {
        await cancelTasks(topicID: topicID)
        try? await store.updateStatus(id: topicID, status: .cancelled)
        postChange()
    }

    func delete(topicID: String) async throws {
        await cancelTasks(topicID: topicID)
        try await store.deleteTopic(id: topicID)
        postChange()
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.background(withIdentifier: Self.sessionIdentifier)
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.waitsForConnectivity = true
        configuration.httpMaximumConnectionsPerHost = 2
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.timeoutIntervalForResource = 60 * 60

        let delegateQueue = OperationQueue()
        delegateQueue.name = "com.eksilik.offline-download-delegate"
        delegateQueue.maxConcurrentOperationCount = 1
        return URLSession(configuration: configuration, delegate: self, delegateQueue: delegateQueue)
    }

    private func enqueuePage(topic: OfflineTopic, page: Int, retryCount: Int) {
        let descriptor = OfflineTransferDescriptor(
            kind: .page,
            topicID: topic.id,
            pageNumber: page,
            sourceURL: nil,
            retryCount: retryCount
        )
        let path = topic.request.settingPage(page).pathAndQuery
        guard let url = URL(string: EksiRouter.baseURL + "/" + path) else {
            Task { await transferFailed(descriptor, message: NetworkError.invalidURL.localizedDescription) }
            return
        }
        enqueue(descriptor: descriptor, url: url)
    }

    private func enqueueMedia(topicID: String, rawURLs: [String]) async {
        for rawURL in ImageURLNormalizer.normalizeStrings(rawURLs) {
            guard await store.localMediaURL(topicID: topicID, sourceURL: rawURL) == nil,
                  let url = URL(string: rawURL) else { continue }
            enqueue(
                descriptor: OfflineTransferDescriptor(
                    kind: .media,
                    topicID: topicID,
                    pageNumber: nil,
                    sourceURL: rawURL,
                    retryCount: 0
                ),
                url: url
            )
        }
    }

    private func enqueue(descriptor: OfflineTransferDescriptor, url: URL) {
        let shouldEnqueue = stateQueue.sync {
            enqueuedKeys.insert(descriptor.key).inserted
        }
        guard shouldEnqueue else { return }

        var request = URLRequest(url: url)
        request.timeoutInterval = 60
        for (key, value) in EksiRouter.defaultHeaders {
            request.setValue(value, forHTTPHeaderField: key)
        }
        if descriptor.kind == .media {
            request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue(EksiRouter.baseURL + "/", forHTTPHeaderField: "Referer")
        }

        let task = session.downloadTask(with: request)
        task.taskDescription = encoded(descriptor)
        if descriptor.retryCount > 0 {
            task.earliestBeginDate = Date().addingTimeInterval(pow(2, Double(descriptor.retryCount)) * 5)
        }
        task.resume()
    }

    private func cancelTasks(topicID: String) async {
        let tasks = await session.allTasks
        for task in tasks {
            guard descriptor(for: task)?.topicID == topicID else { continue }
            task.cancel()
        }
        stateQueue.sync {
            enqueuedKeys = enqueuedKeys.filter { !$0.hasPrefix("\(topicID)|") }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let descriptor = descriptor(for: downloadTask) else { return }

        switch descriptor.kind {
        case .page:
            do {
                let data = try Data(contentsOf: location)
                guard let html = String(data: data, encoding: .utf8) else {
                    throw NetworkError.decodingFailed
                }
                let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
                let acceptedPaywallPage = statusCode == 403
                    && (html.contains("entry-item-list") || html.contains("topic-list"))
                guard (200...299).contains(statusCode) || acceptedPaywallPage else {
                    throw NetworkError.requestFailed(statusCode: statusCode)
                }
                let parsed = EntryPageParser.parse(html: html, currentUsername: nil)
                guard !parsed.title.isEmpty || !parsed.entries.isEmpty else {
                    throw NetworkError.decodingFailed
                }
                let page = OfflineTopicPage(
                    topicID: descriptor.topicID,
                    pageNumber: descriptor.pageNumber ?? 1,
                    title: parsed.title,
                    entries: parsed.entries.map(OfflineEntry.init(entry:))
                )
                let mediaURLs = parsed.entries.flatMap(\.imageURLs)
                    + parsed.entries.compactMap { $0.author.avatarURL }

                Task {
                    do {
                        try await store.savePage(page)
                        await enqueueMedia(topicID: descriptor.topicID, rawURLs: mediaURLs)
                        postChange()
                    } catch {
                        await transferFailed(descriptor, message: error.localizedDescription)
                    }
                }
            } catch {
                Task { await transferFailed(descriptor, message: error.localizedDescription) }
            }

        case .media:
            guard let sourceURL = descriptor.sourceURL else { return }
            let stagingURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("eksilik-media-\(UUID().uuidString)")
            do {
                let statusCode = (downloadTask.response as? HTTPURLResponse)?.statusCode ?? 0
                guard (200...299).contains(statusCode) else {
                    throw NetworkError.requestFailed(statusCode: statusCode)
                }
                try FileManager.default.moveItem(at: location, to: stagingURL)
                Task {
                    do {
                        _ = try await store.saveMedia(
                            from: stagingURL,
                            topicID: descriptor.topicID,
                            sourceURL: sourceURL
                        )
                        postChange()
                    } catch {
                        try? FileManager.default.removeItem(at: stagingURL)
                        await transferFailed(descriptor, message: error.localizedDescription)
                    }
                }
            } catch {
                Task { await transferFailed(descriptor, message: error.localizedDescription) }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let descriptor = descriptor(for: task) else { return }
        stateQueue.async {
            self.enqueuedKeys.remove(descriptor.key)
        }
        if let error {
            if (error as? URLError)?.code == .cancelled { return }
            Task { await transferFailed(descriptor, message: error.localizedDescription) }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        stateQueue.async {
            let handler = self.backgroundCompletionHandler
            self.backgroundCompletionHandler = nil
            DispatchQueue.main.async {
                handler?()
            }
        }
    }

    private func transferFailed(_ descriptor: OfflineTransferDescriptor, message: String) async {
        stateQueue.sync {
            enqueuedKeys.remove(descriptor.key)
        }
        if descriptor.retryCount < 2,
           let topic = try? await store.loadTopic(id: descriptor.topicID) {
            let next = descriptor.retrying()
            switch next.kind {
            case .page:
                enqueuePage(topic: topic, page: next.pageNumber ?? 1, retryCount: next.retryCount)
            case .media:
                if let sourceURL = next.sourceURL, let url = URL(string: sourceURL) {
                    enqueue(descriptor: next, url: url)
                }
            }
        } else if descriptor.kind == .page {
            try? await store.updateStatus(id: descriptor.topicID, status: .failed, errorMessage: message)
            postChange()
        }
    }

    private func postChange() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .offlineTopicsDidChange, object: nil)
        }
    }

    private func encoded(_ descriptor: OfflineTransferDescriptor) -> String? {
        guard let data = try? JSONEncoder().encode(descriptor) else { return nil }
        return data.base64EncodedString()
    }

    private func descriptor(for task: URLSessionTask) -> OfflineTransferDescriptor? {
        guard let value = task.taskDescription,
              let data = Data(base64Encoded: value) else { return nil }
        return try? JSONDecoder().decode(OfflineTransferDescriptor.self, from: data)
    }
}
