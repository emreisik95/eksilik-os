import SwiftUI
import UIKit

@MainActor
private final class CachedImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var error: String?
    @Published var isLoading = false

    private let url: URL?

    init(rawURL: String) {
        url = ImageURLNormalizer.normalize(rawURL)
    }

    func load(force: Bool = false) async {
        guard force || image == nil else { return }
        guard let url else {
            error = ImagePipelineError.invalidURL.localizedDescription
            return
        }

        isLoading = true
        error = nil
        do {
            image = try await ImagePipeline.shared.image(for: url)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }
}

struct CachedRemoteImage: View {
    @StateObject private var loader: CachedImageLoader
    var contentMode: ContentMode = .fill
    var showsRetry = true

    init(url: String, contentMode: ContentMode = .fill, showsRetry: Bool = true) {
        _loader = StateObject(wrappedValue: CachedImageLoader(rawURL: url))
        self.contentMode = contentMode
        self.showsRetry = showsRetry
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.12)

            if let image = loader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                ProgressView()
                    .tint(.gray)
            } else if loader.error != nil {
                Button {
                    Task { await loader.load(force: true) }
                } label: {
                    Image(systemName: showsRetry ? "arrow.clockwise" : "photo")
                        .foregroundColor(.gray)
                        .padding(10)
                }
                .disabled(!showsRetry)
                .accessibilityLabel("görseli yeniden yükle")
            }
        }
        .clipped()
        .task { await loader.load() }
    }
}
