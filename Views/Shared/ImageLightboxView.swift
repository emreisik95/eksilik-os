import SwiftUI
import UIKit

struct ImageLightboxView: View {
    let imageURLs: [String]
    let allowsLocalFiles: Bool
    @State private var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(presentation: ImageGalleryPresentation) {
        imageURLs = presentation.imageURLs
        allowsLocalFiles = presentation.allowsLocalFiles
        _selectedIndex = State(initialValue: presentation.initialIndex)
    }

    private var normalizedURLs: [String] {
        var seen = Set<String>()
        return imageURLs.compactMap { rawValue in
            let value: String?
            if allowsLocalFiles,
               let url = URL(string: rawValue),
               url.isFileURL {
                value = url.absoluteString
            } else {
                value = ImageURLNormalizer.normalize(rawValue)?.absoluteString
            }
            guard let value, seen.insert(value).inserted else { return nil }
            return value
        }
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if normalizedURLs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "photo.badge.exclamationmark")
                        .font(.largeTitle)
                    Text("görsel açılamadı")
                        .font(.subheadline)
                }
                .foregroundColor(.white.opacity(0.8))
            } else {
                TabView(selection: boundedSelection) {
                    ForEach(Array(normalizedURLs.enumerated()), id: \.element) { index, url in
                        ZoomableImage(url: url)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }

            VStack {
                HStack {
                    if normalizedURLs.count > 1 {
                        Text("\(min(selectedIndex + 1, normalizedURLs.count)) / \(normalizedURLs.count)")
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(.black.opacity(0.55), in: Capsule())
                    }
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.body.bold())
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.62), in: Circle())
                    }
                    .accessibilityLabel("kapat")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Spacer()
            }
        }
        .statusBarHidden(true)
        .task {
            selectedIndex = min(max(selectedIndex, 0), max(normalizedURLs.count - 1, 0))
            await ImagePipeline.shared.prefetch(
                normalizedURLs.filter { URL(string: $0)?.isFileURL != true }
            )
        }
    }

    private var boundedSelection: Binding<Int> {
        Binding(
            get: { min(max(selectedIndex, 0), max(normalizedURLs.count - 1, 0)) },
            set: { selectedIndex = $0 }
        )
    }
}

private struct ZoomableImage: View {
    let url: String
    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        image
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(scale)
            .offset(offset)
            .contentShape(Rectangle())
            .gesture(magnificationGesture.simultaneously(with: dragGesture))
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3)) {
                    if scale > 1 {
                        scale = 1
                        committedScale = 1
                        offset = .zero
                        committedOffset = .zero
                    } else {
                        scale = 2
                        committedScale = 2
                    }
                }
            }
    }

    @ViewBuilder
    private var image: some View {
        if let localURL = URL(string: url), localURL.isFileURL {
            if let localImage = UIImage(contentsOfFile: localURL.path) {
                Image(uiImage: localImage)
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "photo.badge.exclamationmark")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
            }
        } else {
            CachedRemoteImage(url: url, contentMode: .fit)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(committedScale * value, 1), 5)
            }
            .onEnded { _ in
                committedScale = scale
                if scale == 1 {
                    offset = .zero
                    committedOffset = .zero
                }
            }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: committedOffset.width + value.translation.width,
                    height: committedOffset.height + value.translation.height
                )
            }
            .onEnded { _ in committedOffset = offset }
    }
}
