import SwiftUI

struct TopicListView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var blockedStore: BlockedTopicStore
    @StateObject private var viewModel: TopicListViewModel

    init(listType: TopicListViewModel.ListType, year: Int? = nil) {
        // BlockedTopicStore will be replaced via onAppear with environment version
        let vm = TopicListViewModel(listType: listType, blockedStore: BlockedTopicStore())
        vm.year = year
        _viewModel = StateObject(wrappedValue: vm)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.topics.isEmpty {
                List {
                    ForEach(0..<12, id: \.self) { i in
                        HStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(themeManager.current.cellSecondaryColor)
                                .frame(height: 14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(width: CGFloat.random(in: 150...280))
                            Spacer()
                            RoundedRectangle(cornerRadius: 10)
                                .fill(themeManager.current.cellSecondaryColor)
                                .frame(width: 36, height: 22)
                        }
                        .padding(.vertical, 2)
                        .listRowBackground(
                            i % 2 == 0
                            ? themeManager.current.cellPrimaryColor
                            : themeManager.current.cellSecondaryColor
                        )
                    }
                }
                .listStyle(.plain)
                .redacted(reason: .placeholder)
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
        .task {
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
        }
        .listStyle(.plain)
    }
}

@ViewBuilder
func destinationView(for route: Route) -> some View {
    switch route {
    case .topicList(let link, let title):
        ChannelTopicListView(link: link, title: title)
    case .entryList(let link, let title):
        EntryListView(link: link, title: title)
    case .entryById(let id):
        EntryListView(link: "entry/\(id)", title: "")
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
