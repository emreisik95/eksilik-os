import SwiftUI

struct SeylerFeedView: View {
    @StateObject private var viewModel = SeylerFeedViewModel()
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    var body: some View {
        VStack(spacing: 0) {
            categoryRail

            Group {
                if viewModel.isLoading && viewModel.stories.isEmpty {
                    LoadingView()
                } else if let error = viewModel.error, viewModel.stories.isEmpty {
                    ErrorView(message: error) {
                        Task { await viewModel.loadStories() }
                    }
                } else if viewModel.stories.isEmpty {
                    EmptyStateView(message: "henüz şey yok")
                } else {
                    storyFeed
                }
            }
        }
        .background(themeManager.current.backgroundColor)
        .task(id: viewModel.selectedCategory) {
            await viewModel.loadStories()
        }
    }

    private var categoryRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(SeylerCategory.allCases) { category in
                        let isSelected = category == viewModel.selectedCategory
                        Button {
                            viewModel.selectedCategory = category
                        } label: {
                            Label(category.title, systemImage: category.systemImage)
                                .font(.subheadline.weight(isSelected ? .bold : .medium))
                                .foregroundColor(
                                    isSelected
                                        ? themeManager.current.backgroundColor
                                        : themeManager.current.labelColor
                                )
                                .padding(.horizontal, 13)
                                .frame(minHeight: 42)
                                .background(
                                    isSelected
                                        ? themeManager.current.accentColor
                                        : themeManager.current.cellSecondaryColor,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                        .id(category.id)
                        .accessibilityValue(isSelected ? "seçili" : "")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(themeManager.current.backgroundColor)
            .overlay(alignment: .bottom) {
                Divider().overlay(themeManager.current.separatorColor.opacity(0.18))
            }
            .onChange(of: viewModel.selectedCategory) { category in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(category.id, anchor: .center)
                }
            }
        }
    }

    private var storyFeed: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(Array(viewModel.stories.enumerated()), id: \.element.id) { index, story in
                    NavigationLink(value: Route.seylerArticle(
                        url: story.url.absoluteString,
                        title: story.title
                    )) {
                        if index == 0 {
                            featuredCard(story)
                        } else {
                            compactCard(story)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .refreshable { await viewModel.loadStories() }
    }

    private func featuredCard(_ story: SeylerStory) -> some View {
        ZStack(alignment: .bottomLeading) {
            storyImage(story)
                .frame(maxWidth: .infinity)
                .frame(height: 230)

            LinearGradient(
                colors: [.clear, .black.opacity(0.88)],
                startPoint: .center,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 8) {
                storyMetadata(story, inverted: true)
                Text(story.title)
                    .font(.system(
                        size: CGFloat(preferences.selectedFontSize + 5),
                        weight: .bold
                    ))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private func compactCard(_ story: SeylerStory) -> some View {
        HStack(spacing: 14) {
            storyImage(story)
                .frame(width: 116, height: 92)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                storyMetadata(story, inverted: false)
                Text(story.title)
                    .font(.system(size: CGFloat(preferences.selectedFontSize), weight: .semibold))
                    .foregroundColor(themeManager.current.labelColor)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 2)

            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .background(
            themeManager.current.cellPrimaryColor,
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(themeManager.current.separatorColor.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func storyImage(_ story: SeylerStory) -> some View {
        if let imageURL = story.imageURL {
            CachedRemoteImage(url: imageURL.absoluteString, showsRetry: false)
        } else {
            ZStack {
                themeManager.current.cellSecondaryColor
                Image(systemName: "text.image")
                    .font(.largeTitle)
                    .foregroundColor(themeManager.current.accentColor.opacity(0.72))
            }
        }
    }

    @ViewBuilder
    private func storyMetadata(_ story: SeylerStory, inverted: Bool) -> some View {
        if story.category != nil || story.readCount != nil {
            HStack(spacing: 8) {
                if let category = story.category {
                    Text(category.lowercased(with: Locale(identifier: "tr_TR")))
                        .font(.caption2.bold())
                }
                if let readCount = story.readCount {
                    Label(readCount, systemImage: "eye")
                        .font(.caption2.weight(.medium))
                }
            }
            .foregroundColor(inverted ? .white.opacity(0.82) : themeManager.current.accentColor)
        }
    }
}
