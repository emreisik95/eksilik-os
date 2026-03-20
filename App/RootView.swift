import SwiftUI

struct RootView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var session = SessionManager.shared
    @StateObject private var blockedStore = BlockedTopicStore()
    @StateObject private var preferences = UserPreferences()
    @StateObject private var deepLinkRouter = DeepLinkRouter()
    @State private var isReady = false
    @State private var didFail = false

    var body: some View {
        ZStack {
            if isReady {
                ContentView()
                    .transition(.opacity)
            }

            if !isReady {
                ZStack {
                    Color(red: 51/255, green: 51/255, blue: 51/255).ignoresSafeArea()

                    Image("splash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 120, height: 120)

                    if didFail {
                        VStack(spacing: 16) {
                            Image(systemName: "wifi.slash")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                            Text(L10n.Common.couldNotConnect)
                                .foregroundColor(.white)
                            Button(L10n.Common.retry) {
                                didFail = false
                                Task { await doBootstrap() }
                            }
                            .buttonStyle(.bordered)
                            .tint(themeManager.current.accentColor)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.7))
                    }
                }
                .transition(.opacity)
            }
        }
        .environmentObject(themeManager)
        .environmentObject(session)
        .environmentObject(blockedStore)
        .environmentObject(preferences)
        .environmentObject(deepLinkRouter)
        .preferredColorScheme(themeManager.current.colorScheme)
        .task { await doBootstrap() }
    }

    private func doBootstrap() async {
        let success = await WebViewFetcher.shared.bootstrap()
        withAnimation {
            if success {
                isReady = true
            } else {
                didFail = true
            }
        }
    }
}
