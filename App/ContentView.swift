import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager

    var body: some View {
        TabView {
            HomeTabView()
                .tabItem { Label(L10n.Tab.home, systemImage: "house") }

            SearchView()
                .tabItem { Label(L10n.Tab.search, systemImage: "magnifyingglass") }

            profileTab
                .tabItem { Label(session.isLoggedIn ? L10n.Tab.profile : L10n.Auth.login, systemImage: "person") }

            SettingsView()
                .tabItem { Label(L10n.Tab.settings, systemImage: "gearshape") }
        }
        .tint(themeManager.current.accentColor)
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
