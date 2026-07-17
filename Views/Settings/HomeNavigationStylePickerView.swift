import SwiftUI

struct HomeNavigationStylePickerView: View {
    @EnvironmentObject private var preferences: UserPreferences
    @EnvironmentObject private var themeManager: ThemeManager

    private let columns = [
        GridItem(.adaptive(minimum: 154), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Label("canlı önizleme", systemImage: "eye.fill")
                            .font(.headline)
                            .foregroundColor(themeManager.current.labelColor)
                        Spacer()
                        Text(preferences.homeNavigationStyle.name)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(themeManager.current.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                themeManager.current.accentColor.opacity(0.12),
                                in: Capsule()
                            )
                    }

                    HomeNavigationPreview(style: preferences.homeNavigationStyle)
                        .id(preferences.homeNavigationStyle.id)
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                .animation(.easeInOut(duration: 0.22), value: preferences.homeNavigationStyle)

                Text("navigasyon biçimleri")
                    .font(.headline)
                    .foregroundColor(themeManager.current.labelColor)

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(HomeNavigationStyle.allCases) { style in
                        styleButton(style)
                    }
                }

                Label(
                    "hangi görünümü seçersen seç, içerikte sağa ve sola kaydırarak sekmeler arasında geçebilirsin.",
                    systemImage: "hand.draw"
                )
                .font(.footnote)
                .foregroundColor(.secondary)
                .padding(14)
                .background(
                    themeManager.current.cellPrimaryColor,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("ana sayfa navigasyonu")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func styleButton(_ style: HomeNavigationStyle) -> some View {
        let isSelected = preferences.homeNavigationStyle == style

        return Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                preferences.homeNavigationStyle = style
            }
        } label: {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: style.systemImage)
                        .font(.title3.weight(.semibold))
                        .frame(width: 30, height: 30)
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                }
                Text(style.name)
                    .font(.body.weight(.bold))
                Text(style.summary)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .opacity(0.76)
            }
            .foregroundColor(isSelected
                ? themeManager.current.backgroundColor
                : themeManager.current.labelColor)
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .topLeading)
            .padding(14)
            .background(
                isSelected
                    ? themeManager.current.accentColor
                    : themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        isSelected
                            ? themeManager.current.accentColor
                            : themeManager.current.separatorColor.opacity(0.2),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(style.name), \(style.summary)")
        .accessibilityValue(isSelected ? "seçili" : "")
    }
}

private struct HomeNavigationPreview: View {
    let style: HomeNavigationStyle

    @EnvironmentObject private var themeManager: ThemeManager

    private let tabs = Array(HomeTabDefinition.all.prefix(4))

    var body: some View {
        ZStack(alignment: .topLeading) {
            themeManager.current.cellPrimaryColor

            VStack(spacing: 0) {
                HStack {
                    Text("ek$ilik")
                        .font(.subheadline.bold())
                    Spacer()
                    Image(systemName: style == .sidebar ? "line.3.horizontal" : "magnifyingglass")
                }
                .foregroundColor(themeManager.current.labelColor)
                .padding(.horizontal, 14)
                .frame(height: 44)

                if style == .topRail {
                    previewTopRail
                }

                previewContent

                if style == .classicBottom {
                    previewClassicBar
                }
            }

            if style == .floatingDock {
                VStack {
                    Spacer()
                    previewFloatingDock
                        .padding(.bottom, 12)
                }
            } else if style == .sidebar {
                previewSidebar
            } else if style == .menuLauncher {
                VStack {
                    Spacer()
                    previewMenuLauncher
                        .padding(.bottom, 12)
                }
            }
        }
        .frame(height: 270)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(themeManager.current.separatorColor.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(style.name) ana sayfa önizlemesi")
    }

    private var previewContent: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(themeManager.current.accentColor.opacity(index == 0 ? 0.22 : 0.1))
                        .frame(width: 34, height: 28)
                    VStack(alignment: .leading, spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeManager.current.labelColor.opacity(0.28))
                            .frame(width: index.isMultiple(of: 2) ? 174 : 132, height: 8)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(themeManager.current.labelColor.opacity(0.12))
                            .frame(width: 92, height: 6)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(maxHeight: .infinity)
                Divider().opacity(0.12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var previewClassicBar: some View {
        HStack(spacing: 0) {
            ForEach(tabs) { tab in
                previewTab(tab, selected: tab.id == "popular", includesLabel: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 5)
        .background(themeManager.current.backgroundColor)
    }

    private var previewTopRail: some View {
        HStack(spacing: 6) {
            ForEach(tabs) { tab in
                Label(tab.name, systemImage: tab.systemImage)
                    .font(.system(size: 9, weight: tab.id == "popular" ? .bold : .medium))
                    .foregroundColor(tab.id == "popular"
                        ? themeManager.current.backgroundColor
                        : themeManager.current.labelColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 7)
                    .background(
                        tab.id == "popular"
                            ? themeManager.current.accentColor
                            : themeManager.current.cellSecondaryColor,
                        in: Capsule()
                    )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }

    private var previewFloatingDock: some View {
        HStack(spacing: 4) {
            ForEach(tabs) { tab in
                previewTab(tab, selected: tab.id == "popular", includesLabel: false)
                    .frame(width: 48, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
        .shadow(color: .black.opacity(0.2), radius: 12, y: 5)
    }

    private var previewSidebar: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text("keşfet")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                ForEach(tabs) { tab in
                    HStack(spacing: 8) {
                        Image(systemName: tab.systemImage)
                            .frame(width: 20)
                        Text(tab.name)
                            .font(.caption.weight(tab.id == "popular" ? .bold : .regular))
                        Spacer()
                    }
                    .foregroundColor(tab.id == "popular"
                        ? themeManager.current.accentColor
                        : themeManager.current.labelColor)
                    .frame(height: 38)
                    .padding(.horizontal, 9)
                    .background(
                        tab.id == "popular"
                            ? themeManager.current.accentColor.opacity(0.12)
                            : Color.clear,
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                }
                Spacer()
            }
            .padding(12)
            .frame(width: 176)
            .background(.regularMaterial)
            Rectangle().fill(.black.opacity(0.28))
        }
    }

    private var previewMenuLauncher: some View {
        HStack(spacing: 10) {
            Image(systemName: "flame.fill")
                .foregroundColor(themeManager.current.accentColor)
            Text("gündem")
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.labelColor)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundColor(.secondary)
            Divider().frame(height: 20)
            Image(systemName: "square.grid.2x2")
                .foregroundColor(themeManager.current.accentColor)
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(themeManager.current.separatorColor.opacity(0.22), lineWidth: 1))
        .shadow(color: .black.opacity(0.18), radius: 10, y: 5)
    }

    private func previewTab(
        _ tab: HomeTabDefinition,
        selected: Bool,
        includesLabel: Bool
    ) -> some View {
        VStack(spacing: 3) {
            Image(systemName: previewSymbol(for: tab, selected: selected))
                .font(.system(size: 12, weight: .semibold))
            if includesLabel {
                Text(tab.name)
                    .font(.system(size: 8, weight: selected ? .bold : .regular))
                    .lineLimit(1)
            }
        }
        .foregroundColor(selected ? themeManager.current.accentColor : .secondary)
        .frame(minHeight: 40)
    }

    private func previewSymbol(for tab: HomeTabDefinition, selected: Bool) -> String {
        guard selected else { return tab.systemImage }
        return tab.systemImage == "calendar" ? "calendar.circle.fill" : "\(tab.systemImage).fill"
    }
}
