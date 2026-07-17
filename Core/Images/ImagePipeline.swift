import Foundation
import UIKit

enum ImagePipelineError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidImage

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "görsel adresi geçersiz"
        case .invalidResponse: return "görsel indirilemedi"
        case .invalidImage: return "görsel açılamadı"
        }
    }
}

actor ImagePipeline {
    static let shared = ImagePipeline()

    private let memoryCache = NSCache<NSURL, UIImage>()
    private let session: URLSession
    private var inFlight: [URL: Task<UIImage, Error>] = [:]

    private init() {
        memoryCache.totalCostLimit = 64 * 1024 * 1024

        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.urlCache = URLCache(
            memoryCapacity: 32 * 1024 * 1024,
            diskCapacity: 256 * 1024 * 1024,
            diskPath: "EksilikImages"
        )
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        session = URLSession(configuration: configuration)
    }

    func image(for url: URL) async throws -> UIImage {
        if let cached = memoryCache.object(forKey: url as NSURL) {
            return cached
        }
        if let task = inFlight[url] {
            return try await task.value
        }

        let session = self.session
        let task = Task<UIImage, Error> {
            var request = URLRequest(url: url)
            request.setValue("image/avif,image/webp,image/apng,image/*,*/*;q=0.8", forHTTPHeaderField: "Accept")
            request.setValue("https://eksisozluk.com/", forHTTPHeaderField: "Referer")
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse,
                  (200...299).contains(response.statusCode) else {
                throw ImagePipelineError.invalidResponse
            }
            guard let image = UIImage(data: data) else {
                throw ImagePipelineError.invalidImage
            }
            return image
        }
        inFlight[url] = task

        do {
            let image = try await task.value
            memoryCache.setObject(image, forKey: url as NSURL, cost: image.memoryCost)
            inFlight[url] = nil
            return image
        } catch {
            inFlight[url] = nil
            throw error
        }
    }

    func prefetch(_ rawURLs: [String]) {
        let urls = ImageURLNormalizer.normalizeStrings(rawURLs).compactMap(URL.init(string:))
        for url in urls where memoryCache.object(forKey: url as NSURL) == nil && inFlight[url] == nil {
            Task { _ = try? await self.image(for: url) }
        }
    }
}

private extension UIImage {
    var memoryCost: Int {
        guard let cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
