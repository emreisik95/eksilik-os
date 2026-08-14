import SwiftUI

struct SeylerReaderView: View {
    @StateObject private var viewModel: SeylerArticleViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @State private var galleryPresentation: ImageGalleryPresentation?

    init(url: URL) {
        _viewModel = StateObject(wrappedValue: SeylerArticleViewModel(url: url))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.article == nil {
                LoadingView()
            } else if let error = viewModel.error, viewModel.article == nil {
                ErrorView(message: error) {
                    Task { await viewModel.loadArticle(force: true) }
                }
            } else if let article = viewModel.article {
                articleView(article)
            } else {
                EmptyStateView(message: "içerik okunamadı")
            }
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("şeyler")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let article = viewModel.article {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ShareLink(item: article.sourceURL) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .accessibilityLabel("paylaş")
                }
            }
        }
        .fullScreenCover(item: $galleryPresentation) { presentation in
            ImageLightboxView(presentation: presentation)
        }
        .task {
            await viewModel.loadArticle()
        }
        .task(id: viewModel.article?.sourceURL) {
            guard let article = viewModel.article else { return }
            await ImagePipeline.shared.prefetch(article.imageURLs.map(\.absoluteString))
        }
    }

    private func articleView(_ article: SeylerArticle) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                metadata(article)

                Text(article.title)
                    .font(.system(size: CGFloat(preferences.selectedFontSize + 10), weight: .bold))
                    .foregroundColor(themeManager.current.labelColor)
                    .fixedSize(horizontal: false, vertical: true)

                if let summary = article.summary {
                    Text(summary)
                        .font(.system(size: CGFloat(preferences.selectedFontSize + 2), weight: .medium))
                        .foregroundColor(themeManager.current.entryTextColor.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let heroImageURL = article.heroImageURL {
                    articleImage(url: heroImageURL, caption: nil, article: article)
                }

                ForEach(Array(article.blocks.enumerated()), id: \.offset) { _, block in
                    articleBlock(block, article: article)
                }

                if !article.authors.isEmpty {
                    Label(article.authors.joined(separator: ", "), systemImage: "person.crop.circle")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(themeManager.current.accentColor)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .textSelection(.enabled)
        .refreshable { await viewModel.loadArticle(force: true) }
    }

    @ViewBuilder
    private func metadata(_ article: SeylerArticle) -> some View {
        if article.category != nil || article.date != nil || article.readCount != nil {
            HStack(spacing: 9) {
                if let category = article.category {
                    Text(category.lowercased(with: Locale(identifier: "tr_TR")))
                        .font(.caption.bold())
                        .foregroundColor(themeManager.current.backgroundColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(themeManager.current.accentColor, in: Capsule())
                }
                if let date = article.date {
                    Text(date)
                        .font(.caption)
                        .foregroundColor(themeManager.current.dateColor)
                }
                Spacer(minLength: 0)
                if let readCount = article.readCount {
                    Label(readCount, systemImage: "eye")
                        .font(.caption)
                        .foregroundColor(themeManager.current.dateColor)
                }
            }
        }
    }

    @ViewBuilder
    private func articleBlock(_ block: SeylerArticleBlock, article: SeylerArticle) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
                .font(.system(size: CGFloat(preferences.selectedFontSize)))
                .foregroundColor(themeManager.current.entryTextColor)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        case .heading(let text):
            Text(text)
                .font(.system(size: CGFloat(preferences.selectedFontSize + 4), weight: .bold))
                .foregroundColor(themeManager.current.labelColor)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
        case .image(let url, let caption):
            articleImage(url: url, caption: caption, article: article)
        case .quote(let text):
            Text(text)
                .font(.system(size: CGFloat(preferences.selectedFontSize), weight: .medium))
                .italic()
                .foregroundColor(themeManager.current.entryTextColor)
                .padding(.leading, 14)
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(themeManager.current.accentColor)
                        .frame(width: 4)
                }
        case .list(let items):
            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 9) {
                        Circle()
                            .fill(themeManager.current.accentColor)
                            .frame(width: 5, height: 5)
                        Text(item)
                            .font(.system(size: CGFloat(preferences.selectedFontSize)))
                            .foregroundColor(themeManager.current.entryTextColor)
                    }
                }
            }
        }
    }

    private func articleImage(
        url: URL,
        caption: String?,
        article: SeylerArticle
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                let urls = article.imageURLs.map(\.absoluteString)
                galleryPresentation = ImageGalleryPresentation(
                    imageURLs: urls,
                    initialIndex: article.imageURLs.firstIndex(of: url) ?? 0
                )
            } label: {
                CachedRemoteImage(url: url.absoluteString, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 190, maxHeight: 460)
                    .background(themeManager.current.cellSecondaryColor)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("görseli tam ekran aç")

            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundColor(themeManager.current.dateColor)
            }
        }
    }
}
