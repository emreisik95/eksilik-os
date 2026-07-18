import SwiftUI

struct TopicListView: View {
    @StateObject private var viewModel: TopicListViewModel

    init(listType: TopicListViewModel.ListType, year: Int? = nil) {
        let vm = TopicListViewModel(listType: listType)
        vm.year = year
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        TopicListContentView(viewModel: viewModel)
    }
}

struct TopicListContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var blockedStore: BlockedTopicStore
    @ObservedObject var viewModel: TopicListViewModel

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.topics.isEmpty {
                TopicListSkeletonView()
            } else if let error = viewModel.error, viewModel.topics.isEmpty {
                ErrorView(message: error) {
                    print("🔄 Retry tapped for \(viewModel.listType)")
                    Task { await viewModel.loadTopics() }
                }
            } else if viewModel.topics.isEmpty {
                EmptyStateView(message: L10n.Common.noTopics)
            } else {
                topicList
            }
        }
        .background(themeManager.current.backgroundColor)
        .task(id: viewModel.listType.rawValue) {
            viewModel.configure(blockedStore: blockedStore)
            guard viewModel.topics.isEmpty else { return }
            await viewModel.loadTopics()
        }
        .refreshable { await viewModel.loadTopics() }
    }

    private var topicList: some View {
        List {
            ForEach(Array(viewModel.topics.enumerated()), id: \.element.id) { index, topic in
                NavigationLink(value: Route.entryList(link: topic.link, title: topic.title)) {
                    TopicRowView(topic: topic, isEven: index % 2 == 0)
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(
                    index % 2 == 0
                    ? themeManager.current.cellPrimaryColor
                    : themeManager.current.cellSecondaryColor
                )
                .swipeActions(edge: .leading) {
                    Button(L10n.Home.block) {
                        viewModel.blockTopic(topic.title)
                    }
                    .tint(themeManager.current.accentColor)
                }
                .contextMenu {
                    Button {
                        blockedStore.addRule(FilterRule(id: UUID(), pattern: topic.title, type: .exact, isEnabled: true))
                        viewModel.topics.removeAll { $0.title == topic.title }
                    } label: {
                        Label(L10n.Home.block, systemImage: "nosign")
                    }
                    Button {
                        blockedStore.addRule(FilterRule(id: UUID(), pattern: topic.title, type: .contains, isEnabled: true))
                        viewModel.topics.removeAll { $0.title.lowercased().contains(topic.title.lowercased()) }
                    } label: {
                        Label(L10n.Home.blockContaining, systemImage: "text.badge.xmark")
                    }
                }
                .onAppear {
                    if topic.id == viewModel.topics.last?.id {
                        Task { await viewModel.loadMore() }
                    }
                }
            }

            if viewModel.isLoadingMore {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowBackground(themeManager.current.backgroundColor)
            }
        }
        .listStyle(.plain)
    }
}

@ViewBuilder
func destinationView(for route: Route) -> some View {
    Group {
        switch route {
        case .topicList(let link, let title):
            ChannelTopicListView(link: link, title: title)
        case .entryList(let link, let title):
            EntryListView(link: link, title: title)
        case .entryById(let id):
            EntryListView(link: "entry/\(id)", title: "")
        case .topicFeed(let source):
            switch source {
            case "gundem":
                TopicListView(listType: .popular)
                    .navigationTitle("gündem")
            case "bugun":
                TopicListView(listType: .today)
                    .navigationTitle("bugün")
            case "takip":
                FollowingFeedView()
                    .navigationTitle("takip")
            case "debe":
                TopicListView(listType: .debe)
                    .navigationTitle("debe")
            default:
                EmptyView()
            }
        case .profile(let username):
            ProfileView(username: username)
        case .composeEntry(let link):
            EntryComposeView(topicLink: link)
        case .favoriteUsers(let entryId):
            FavoriteUsersView(entryId: entryId)
        case .messageThread(let link, let title):
            MessageThreadView(link: link, title: title)
        case .composeMessage(let to, let subject):
            MessageComposeView(recipient: to, subject: subject)
        case .login:
            LoginView()
        case .settings:
            SettingsView()
        case .webPage(let urlStr, let title):
            if let url = URL(string: urlStr) {
                EksiWebView(url: url)
                    .navigationTitle(title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        default:
            EmptyView()
        }
    }
}
