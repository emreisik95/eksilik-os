import SwiftUI

struct HomeTabView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var preferences: UserPreferences
    @StateObject private var nav = NavigationCoordinator()
    @State private var selectedTab: TopicListViewModel.ListType = .popular
    @State private var selectedYear: Int?
    @State private var isSidebarOpen = false

    private var tabs: [HomeTabItem] {
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

    private var selectedItem: HomeTabItem? {
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
        .onAppear(perform: ensureValidSelection)
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
            DebeView()
                .id(selectedTab)
        } else if selectedTab == .todayInHistory {
            TopicListView(listType: selectedTab, year: selectedYear)
                .id("todayInHistory-\(selectedYear ?? 0)")
        } else {
            TopicListView(listType: selectedTab)
                .id(selectedTab)
        }
    }

    // MARK: - Navigation Shells

    private var classicBottomBar: some View {
        Group {
            if tabs.count <= 5 {
                HStack(spacing: 0) {
                    ForEach(tabs) { item in
                        classicTabButton(item)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(tabs) { item in
                            classicTabButton(item)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .background(themeManager.current.backgroundColor)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(themeManager.current.separatorColor.opacity(0.18))
                .frame(height: 1)
        }
    }

    private func classicTabButton(_ item: HomeTabItem) -> some View {
        let isSelected = selectedTab == item.listType

        return Button {
            select(item)
        } label: {
            VStack(spacing: 4) {
                Image(systemName: selectedSymbol(for: item.definition, isSelected: isSelected))
                    .font(.system(size: 16, weight: .semibold))
                Text(item.definition.name)
                    .font(.caption2.weight(isSelected ? .bold : .regular))
                    .lineLimit(1)
            }
            .foregroundColor(isSelected ? themeManager.current.accentColor : .secondary)
            .padding(.horizontal, 12)
            .frame(minWidth: 62, minHeight: 52)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) {
            if isSelected {
                Capsule()
                    .fill(themeManager.current.accentColor)
                    .frame(width: 28, height: 3)
            }
        }
        .accessibilityLabel(item.definition.name)
        .accessibilityValue(isSelected ? "seçili" : "")
    }

    private var topRail: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tabs) { item in
                        let isSelected = selectedTab == item.listType
                        Button {
                            select(item)
                        } label: {
                            Label(
                                item.definition.name,
                                systemImage: selectedSymbol(for: item.definition, isSelected: isSelected)
                            )
                            .font(.subheadline.weight(isSelected ? .bold : .medium))
                            .foregroundColor(isSelected
                                ? themeManager.current.backgroundColor
                                : themeManager.current.labelColor)
                            .padding(.horizontal, 13)
                            .frame(minHeight: 44)
                            .background(
                                isSelected
                                    ? themeManager.current.accentColor
                                    : themeManager.current.cellSecondaryColor,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .id(item.id)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
            }
            .background(themeManager.current.backgroundColor)
            .onChange(of: selectedTab) { _ in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(selectedTab.rawValue, anchor: .center)
                }
            }
        }
    }

    private var floatingDock: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { item in
                        let isSelected = selectedTab == item.listType
                        Button {
                            select(item)
                        } label: {
                            HStack(spacing: 7) {
                                Image(systemName: selectedSymbol(for: item.definition, isSelected: isSelected))
                                    .font(.system(size: 17, weight: .semibold))
                                if isSelected {
                                    Text(item.definition.name)
                                        .font(.caption.weight(.bold))
                                        .lineLimit(1)
                                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                                }
                            }
                            .foregroundColor(isSelected
                                ? themeManager.current.backgroundColor
                                : themeManager.current.labelColor.opacity(0.72))
                            .padding(.horizontal, isSelected ? 14 : 12)
                            .frame(minHeight: 48)
                            .background(
                                isSelected ? themeManager.current.accentColor : Color.clear,
                                in: Capsule()
                            )
                        }
                        .buttonStyle(.plain)
                        .id(item.id)
                    }
                }
                .padding(5)
            }
            .background(.ultraThinMaterial, in: Capsule())
            .overlay {
                Capsule()
                    .stroke(themeManager.current.separatorColor.opacity(0.22), lineWidth: 1)
            }
            .shadow(color: .black.opacity(0.22), radius: 14, y: 6)
            .onChange(of: selectedTab) { _ in
                withAnimation(.easeInOut(duration: 0.22)) {
                    proxy.scrollTo(selectedTab.rawValue, anchor: .center)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
    }

    private var menuLauncher: some View {
        HStack(spacing: 0) {
            Menu {
                ForEach(tabs) { item in
                    Button {
                        select(item)
                    } label: {
                        Label(
                            item.definition.name,
                            systemImage: selectedSymbol(
                                for: item.definition,
                                isSelected: selectedTab == item.listType
                            )
                        )
                    }
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: selectedItem.map {
                        selectedSymbol(for: $0.definition, isSelected: true)
                    } ?? "square.grid.2x2")
                        .foregroundColor(themeManager.current.accentColor)
                    Text(selectedItem?.definition.name ?? L10n.Home.gundem)
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(themeManager.current.labelColor)
                        .lineLimit(1)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 18)
                .frame(minHeight: 50)
            }

            Divider()
                .frame(height: 24)

            Menu {
                ForEach(tabs) { item in
                    Button {
                        select(item)
                    } label: {
                        Label(item.definition.name, systemImage: item.definition.systemImage)
                    }
                }
            } label: {
                Image(systemName: "square.grid.2x2.fill")
                    .font(.title3)
                    .foregroundColor(themeManager.current.accentColor)
                    .frame(width: 52, height: 50)
            }
            .accessibilityLabel("tüm sekmeler")
        }
        .background(.ultraThinMaterial, in: Capsule())
        .overlay {
            Capsule()
                .stroke(themeManager.current.separatorColor.opacity(0.22), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
        .frame(maxWidth: .infinity)
    }

    private var sidebarOverlay: some View {
        GeometryReader { proxy in
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .foregroundColor(themeManager.current.accentColor)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("keşfet")
                                .font(.headline)
                            Text("sekmeni seç")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .frame(height: 68)

                    ScrollView {
                        VStack(spacing: 5) {
                            ForEach(tabs) { item in
                                sidebarButton(item)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.bottom, 16)
                    }

                    Divider().opacity(0.2)

                    Button {
                        isSidebarOpen = false
                        nav.push(.settings)
                    } label: {
                        Label("ayarlar", systemImage: "gearshape")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(themeManager.current.labelColor)
                            .padding(.horizontal, 18)
                            .frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                }
                .frame(width: min(proxy.size.width * 0.82, 310))
                .background(.regularMaterial)
                .shadow(color: .black.opacity(0.3), radius: 18, x: 8)
                .transition(.move(edge: .leading))

                Button {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                        isSidebarOpen = false
                    }
                } label: {
                    Color.black.opacity(0.34)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("yan paneli kapat")
            }
        }
        .ignoresSafeArea(edges: .bottom)
    }

    private func sidebarButton(_ item: HomeTabItem) -> some View {
        let isSelected = selectedTab == item.listType

        return Button {
            select(item)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.9)) {
                isSidebarOpen = false
            }
        } label: {
            HStack(spacing: 13) {
                Image(systemName: selectedSymbol(for: item.definition, isSelected: isSelected))
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 28)
                Text(item.definition.name)
                    .font(.body.weight(isSelected ? .bold : .medium))
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .foregroundColor(isSelected
                ? themeManager.current.accentColor
                : themeManager.current.labelColor)
            .padding(.horizontal, 13)
            .frame(minHeight: 52)
            .background(
                isSelected
                    ? themeManager.current.accentColor.opacity(0.13)
                    : Color.clear,
                in: RoundedRectangle(cornerRadius: 14, style: .continuous)
            )
        }
        .buttonStyle(.plain)
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

    private func select(_ item: HomeTabItem) {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectedTab = item.listType
        }
    }

    private func ensureValidSelection() {
        guard !tabs.contains(where: { $0.listType == selectedTab }),
              let first = tabs.first else { return }
        selectedTab = first.listType
    }

    private func selectedSymbol(for tab: HomeTabDefinition, isSelected: Bool) -> String {
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

private struct HomeTabItem: Identifiable {
    let definition: HomeTabDefinition
    let listType: TopicListViewModel.ListType

    var id: String { definition.id }
}
