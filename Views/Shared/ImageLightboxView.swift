import SwiftUI

struct ImageLightboxView: View {
    let imageURLs: [String]
    @State private var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss

    init(presentation: ImageGalleryPresentation) {
        imageURLs = presentation.imageURLs
        _selectedIndex = State(initialValue: presentation.initialIndex)
    }

    private var normalizedURLs: [String] {
        ImageURLNormalizer.normalizeStrings(imageURLs)
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
                        ZoomableRemoteImage(url: url)
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
            await ImagePipeline.shared.prefetch(normalizedURLs)
        }
    }

    private var boundedSelection: Binding<Int> {
        Binding(
            get: { min(max(selectedIndex, 0), max(normalizedURLs.count - 1, 0)) },
            set: { selectedIndex = $0 }
        )
    }
}

private struct ZoomableRemoteImage: View {
    let url: String
    @State private var scale: CGFloat = 1
    @State private var committedScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var committedOffset: CGSize = .zero

    var body: some View {
        CachedRemoteImage(url: url, contentMode: .fit)
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
