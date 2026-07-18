import SwiftUI

struct FollowingFeedView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @StateObject private var writtenViewModel: TopicListViewModel
    @StateObject private var favoritedViewModel: TopicListViewModel
    @State private var selectedSection: FollowingFeedSection = .written

    init() {
        _writtenViewModel = StateObject(
            wrappedValue: TopicListViewModel(listType: .following)
        )
        _favoritedViewModel = StateObject(
            wrappedValue: TopicListViewModel(listType: .followingFavorites)
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            sectionPicker

            TopicListContentView(
                viewModel: activeViewModel,
                emptyMessage: selectedSection.emptyMessage
            )
                .id(selectedSection)
        }
        .background(themeManager.current.backgroundColor)
    }

    private var sectionPicker: some View {
        Picker("takip akışı", selection: $selectedSection) {
            ForEach(FollowingFeedSection.allCases) { section in
                Text(section.title)
                    .tag(section)
            }
        }
        .pickerStyle(.segmented)
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(themeManager.current.backgroundColor)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(themeManager.current.separatorColor.opacity(0.2))
                .frame(height: 1)
        }
        .accessibilityLabel("takip akışı")
    }

    private var activeViewModel: TopicListViewModel {
        switch selectedSection {
        case .written:
            return writtenViewModel
        case .favorited:
            return favoritedViewModel
        }
    }
}
