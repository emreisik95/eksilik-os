import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager

    var body: some View {
        TabView {
            ForEach(MainTab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tabTitle(for: tab), systemImage: tab.systemImage)
                    }
            }
        }
        .tint(themeManager.current.accentColor)
    }

    @ViewBuilder
    private func tabContent(for tab: MainTab) -> some View {
        switch tab {
        case .home:
            HomeTabView()
        case .search:
            SearchView()
        case .events:
            eventsTab
        case .profile:
            profileTab
        case .settings:
            SettingsView()
        }
    }

    private func tabTitle(for tab: MainTab) -> String {
        if tab == .profile, !session.isLoggedIn {
            return L10n.Auth.login
        }
        return tab.title
    }

    private var eventsTab: some View {
        NavigationStack {
            TopicListView(listType: .events)
                .navigationTitle(L10n.Tab.events)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
        }
    }

    @ViewBuilder
    private var profileTab: some View {
        if session.isLoggedIn, let username = session.username, !username.isEmpty {
            ProfileView(username: username, isRoot: true)
        } else {
            NavigationStack {
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.gray)
                    NavigationLink(value: Route.login) {
                        Text(L10n.Auth.login)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 10)
                            .background(themeManager.current.accentColor)
                            .cornerRadius(10)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(themeManager.current.backgroundColor.ignoresSafeArea())
                .navigationTitle(L10n.Auth.login)
                .navigationBarTitleDisplayMode(.inline)
                .navigationDestination(for: Route.self) { route in
                    destinationView(for: route)
                }
            }
        }
    }
}
