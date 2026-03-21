import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var preferences: UserPreferences
    @StateObject private var nav = NavigationCoordinator()
    @State private var selectedTab: TopicListViewModel.ListType = .popular
    @State private var selectedYear: Int? = nil

    private var tabs: [(String, TopicListViewModel.ListType)] {
        var list: [(String, TopicListViewModel.ListType)] = [
            (L10n.Home.gundem, .popular),
            (L10n.Home.bugun, .today),
            (L10n.Home.debe, .debe),
            (L10n.Home.tarihte, .todayInHistory),
        ]
        if session.isLoggedIn {
            list.append(contentsOf: [
                (L10n.Home.son, .latest),
                (L10n.Home.takip, .following),
                (L10n.Home.kenar, .kenar),
            ])
        }
        list.append((L10n.Home.caylaklar, .caylaklar))
        if session.isLoggedIn {
            list.append((L10n.Home.cop, .cop))
        }
        let visible = preferences.visibleHomeTabs
        if !visible.isEmpty {
            list = list.filter { visible.contains($0.1.rawValue) }
        }
        return list
    }

    private static let historyYears: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((1999...current).reversed())
    }()

    var body: some View {
        NavigationStack(path: $nav.path) {
            VStack(spacing: 0) {
                // Top position
                if preferences.homeTabBarPosition == "top" {
                    tabBar
                    if selectedTab == .todayInHistory { yearPickerBar }
                }

                // Content
                if selectedTab == .debe {
                    DebeView()
                } else if selectedTab == .todayInHistory {
                    TopicListView(listType: selectedTab, year: selectedYear)
                        .id("todayInHistory-\(selectedYear ?? 0)")
                } else {
                    TopicListView(listType: selectedTab)
                        .id(selectedTab)
                }

                // Bottom position
                if preferences.homeTabBarPosition == "bottom" {
                    if selectedTab == .todayInHistory { yearPickerBar }
                    tabBar
                }
            }
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(L10n.Home.title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(nav)
        .onChange(of: session.isLoggedIn) { _ in
            if !session.isLoggedIn && [.latest, .following, .kenar, .cop].contains(selectedTab) {
                selectedTab = .popular
            }
        }
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        Group {
            if tabs.count <= 5 {
                // Few tabs: fill width evenly
                HStack(spacing: 0) {
                    ForEach(tabs, id: \.1) { tab in
                        tabButton(tab)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                // Many tabs: scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs, id: \.1) { tab in
                            tabButton(tab)
                        }
                    }
                }
            }
        }
        .background(themeManager.current.backgroundColor)
    }

    private func tabButton(_ tab: (String, TopicListViewModel.ListType)) -> some View {
        Button {
            selectedTab = tab.1
        } label: {
            Text(tab.0)
                .font(.system(size: CGFloat(preferences.selectedFontSize - 1), weight: selectedTab == tab.1 ? .bold : .regular))
                .foregroundColor(selectedTab == tab.1
                    ? themeManager.current.labelColor
                    : .gray)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
        }
        .overlay(alignment: preferences.homeTabBarPosition == "bottom" ? .top : .bottom) {
            if selectedTab == tab.1 {
                Rectangle()
                    .fill(themeManager.current.accentColor)
                    .frame(height: 2)
            }
        }
    }

    // MARK: - Year Picker

    private var yearPickerBar: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Self.historyYears, id: \.self) { year in
                        Button {
                            selectedYear = (selectedYear == year) ? nil : year
                        } label: {
                            Text(String(year))
                                .font(.caption.weight(selectedYear == year ? .bold : .regular))
                                .foregroundColor(selectedYear == year
                                    ? themeManager.current.backgroundColor
                                    : themeManager.current.labelColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(selectedYear == year
                                            ? themeManager.current.accentColor
                                            : themeManager.current.cellSecondaryColor)
                                )
                        }
                        .id(year)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .background(themeManager.current.backgroundColor)
            .onAppear {
                if let year = selectedYear {
                    proxy.scrollTo(year, anchor: .center)
                }
            }
        }
    }
}
