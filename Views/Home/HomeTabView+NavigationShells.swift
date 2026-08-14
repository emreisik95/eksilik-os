import SwiftUI

extension HomeTabView {
    var classicBottomBar: some View {
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

    var topRail: some View {
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

    var floatingDock: some View {
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

    var menuLauncher: some View {
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

    var sidebarOverlay: some View {
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
}
