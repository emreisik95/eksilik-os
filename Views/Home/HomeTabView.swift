import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject var preferences: UserPreferences
    @EnvironmentObject private var deepLinkRouter: DeepLinkRouter
    @StateObject var nav = NavigationCoordinator()
    @State var selectedTab = TopicListViewModel.ListType(rawValue: HomeTabCatalog.initialID) ?? .popular
    @State private var selectedYear: Int?
    @State var isSidebarOpen = false

    var tabs: [HomeTabItem] {
        HomeTabCatalog.availableTabs(
            order: preferences.homeTabOrder,
            visible: preferences.visibleHomeTabs,
            isLoggedIn: session.isLoggedIn
        ).compactMap { definition in
            guard let listType = TopicListViewModel.ListType(rawValue: definition.id) else {
                return nil
            }
            return HomeTabItem(definition: definition, listType: listType)
        }
    }

    var selectedItem: HomeTabItem? {
        tabs.first { $0.listType == selectedTab }
    }

    private static let historyYears: [Int] = {
        let current = Calendar.current.component(.year, from: Date())
        return Array((1999...current).reversed())
    }()

    var body: some View {
        NavigationStack(path: $nav.path) {
            ZStack(alignment: .leading) {
                mainSurface

                if preferences.homeNavigationStyle == .sidebar, isSidebarOpen {
                    sidebarOverlay
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(L10n.Home.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if preferences.homeNavigationStyle == .sidebar {
                        Button {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.86)) {
                                isSidebarOpen.toggle()
                            }
                        } label: {
                            Image(systemName: isSidebarOpen ? "xmark" : "line.3.horizontal")
                                .frame(width: 44, height: 44)
                        }
                        .accessibilityLabel(isSidebarOpen ? "yan paneli kapat" : "yan paneli aç")
                    }
                }
            }
            .navigationDestination(for: Route.self) { route in
                destinationView(for: route)
            }
        }
        .environmentObject(nav)
        .onAppear {
            ensureValidSelection()
            consumePendingDeepLink()
        }
        .onChange(of: deepLinkRouter.pendingRoute) { _ in
            consumePendingDeepLink()
        }
        .onChange(of: deepLinkRouter.homeReselectionToken) { _ in
            resetToGundem()
        }
        .onChange(of: session.isLoggedIn) { _ in
            ensureValidSelection()
        }
        .onChange(of: preferences.visibleHomeTabs) { _ in
            ensureValidSelection()
        }
        .onChange(of: preferences.homeTabOrder) { _ in
            ensureValidSelection()
        }
        .onChange(of: preferences.homeNavigationStyle) { style in
            if style != .sidebar {
                isSidebarOpen = false
            }
        }
    }

    private func consumePendingDeepLink() {
        guard deepLinkRouter.selectedMainTab == .home,
              let route = deepLinkRouter.consumeRoute() else { return }
        nav.popToRoot()
        nav.push(route)
    }

    private func resetToGundem() {
        nav.popToRoot()
        selectedYear = nil
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = .popular
            isSidebarOpen = false
        }
    }

    private var mainSurface: some View {
        VStack(spacing: 0) {
            if preferences.homeNavigationStyle == .topRail {
                topRail
            }

            if selectedTab == .todayInHistory {
                yearPickerBar
            }

            tabContent
                .contentShape(Rectangle())
                .simultaneousGesture(tabSwipeGesture)

            if preferences.homeNavigationStyle == .classicBottom {
                classicBottomBar
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            switch preferences.homeNavigationStyle {
            case .floatingDock:
                floatingDock
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            case .menuLauncher:
                menuLauncher
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            case .classicBottom, .topRail, .sidebar:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        if selectedTab == .debe {
            DebeView().id(selectedTab)
        } else if selectedTab == .eksiSeyler {
            SeylerFeedView().id(selectedTab)
        } else if selectedTab == .following {
            FollowingFeedView().id(selectedTab)
        } else if selectedTab == .todayInHistory {
            TopicListView(listType: selectedTab, year: selectedYear)
                .id("todayInHistory-\(selectedYear ?? 0)")
        } else {
            TopicListView(listType: selectedTab)
                .id(selectedTab)
        }
    }

    // MARK: - Selection and Swipe

    private var tabSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 34)
            .onEnded { value in
                guard let step = HomeNavigationPolicy.step(
                    horizontal: Double(value.translation.width),
                    vertical: Double(value.translation.height)
                ) else { return }
                moveSelection(by: step)
            }
    }

    private func moveSelection(by step: Int) {
        let ids = tabs.map(\.id)
        let nextID = HomeNavigationPolicy.adjacentTabID(
            in: ids,
            selected: selectedTab.rawValue,
            step: step
        )
        guard nextID != selectedTab.rawValue,
              let item = tabs.first(where: { $0.id == nextID }) else { return }
        select(item)
    }

    func select(_ item: HomeTabItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = item.listType
        }
    }

    private func ensureValidSelection() {
        guard !tabs.contains(where: { $0.listType == selectedTab }),
              let first = tabs.first else { return }
        selectedTab = first.listType
    }

    func selectedSymbol(for tab: HomeTabDefinition, isSelected: Bool) -> String {
        guard isSelected else { return tab.systemImage }
        if tab.systemImage == "calendar" {
            return "calendar.circle.fill"
        }
        switch tab.systemImage {
        case "flame", "sun.max", "crown", "clock", "bell", "bookmark", "leaf", "trash":
            return "\(tab.systemImage).fill"
        default:
            return tab.systemImage
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
                                .frame(minHeight: 36)
                                .background(
                                    selectedYear == year
                                        ? themeManager.current.accentColor
                                        : themeManager.current.cellSecondaryColor,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
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

struct HomeTabItem: Identifiable {
    let definition: HomeTabDefinition
    let listType: TopicListViewModel.ListType

    var id: String { definition.id }
}
