import SwiftUI

extension SettingsView {
    // An exhaustive declarative SettingsItem-to-view mapping is clearer than
    // type-erased closure tables, despite counting as switch complexity.
    @ViewBuilder
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func settingsItem(_ item: SettingsItem) -> some View {
        switch item {
        case .theme:
            navigationRow(
                destination: ThemePickerView(),
                icon: "circle.lefthalf.filled",
                title: "tema",
                detail: themeManager.current.name
            )
        case .entryLayout:
            navigationRow(
                destination: EntryLayoutPickerView(),
                icon: "rectangle.split.3x1",
                title: "entry görünümü",
                detail: preferences.entryLayoutStyle.name
            )
        case .fontSize:
            fontSizeRow
        case .filterStyle:
            filterStyleRow
        case .appIcon:
            NavigationLink {
                AppIconPickerView(selectedIconName: $currentIconName)
            } label: {
                SettingsNavigationRow(icon: "app.dashed", title: "uygulama ikonu", detail: currentIconTitle)
            }
            .buttonStyle(.plain)
        case .homeNavigation:
            navigationRow(
                destination: HomeNavigationStylePickerView(),
                icon: "rectangle.bottomthird.inset.filled",
                title: "navigasyon görünümü",
                detail: preferences.homeNavigationStyle.name
            )
        case .homeTabs:
            navigationRow(
                destination: TabCustomizationView(),
                icon: "square.grid.2x2",
                title: "sekmeleri düzenle",
                subtitle: "sırala, göster veya gizle"
            )
        case .offlineLibrary:
            navigationRow(
                destination: OfflineLibraryView(),
                icon: "arrow.down.circle",
                title: "çevrimdışı okuma",
                subtitle: "indirilen başlık ve yazıları yönet"
            )
        case .blockedTopics:
            navigationRow(
                destination: BlockedTopicsView(),
                icon: "eye.slash",
                title: "engellenen başlıklar",
                subtitle: "içerik filtrelerini düzenle"
            )
        case .login:
            NavigationLink {
                LoginView()
            } label: {
                SettingsNavigationRow(
                    icon: "person.badge.key",
                    title: "giriş yap",
                    subtitle: "mevcut ekşi sözlük oturumunu kullan",
                    isAccented: true
                )
            }
            .buttonStyle(.plain)
        case .accountPreferences:
            webSettingsRow(
                path: "/ayarlar/tercihler",
                navigationTitle: "tercihler",
                icon: "person.text.rectangle",
                title: "hesap tercihleri",
                subtitle: "web hesabındaki seçenekler"
            )
        case .trackingAndBlocks:
            webSettingsRow(
                path: "/takip-engellenmis",
                navigationTitle: "takip / engellenmişler",
                icon: "person.2.slash",
                title: "takip ve engellenmişler"
            )
        case .logout:
            logoutRow
        case .privacyPolicy:
            externalRow(
                destination: SettingsProjectLink.privacyPolicy,
                icon: "hand.raised",
                title: L10n.Settings.privacyPolicy,
                subtitle: "verilerin nasıl işlendiğini gör"
            )
        case .support:
            externalRow(
                destination: SettingsProjectLink.support,
                icon: "questionmark.bubble",
                title: L10n.Settings.support,
                subtitle: "yardım al veya sorun bildir"
            )
        case .server:
            NavigationLink {
                ServerSettingsView(baseURL: $preferences.baseURL)
            } label: {
                SettingsNavigationRow(
                    icon: "network",
                    title: "sunucu adresi",
                    detail: URL(string: preferences.baseURL)?.host ?? "özel"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var filterStyleRow: some View {
        HStack(spacing: 12 * layoutScale) {
            SettingsRowIcon(systemImage: "line.3.horizontal.decrease.circle")
            VStack(alignment: .leading, spacing: 3 * layoutScale) {
                Text("filtre görünümü")
                    .settingsFont(baseSize: 17)
                    .foregroundColor(themeManager.current.labelColor)
                Text("metin yerine sade ikonlar kullan")
                    .settingsFont(baseSize: 12)
                    .foregroundColor(themeManager.current.dateColor)
            }
            Spacer(minLength: 8 * layoutScale)
            Toggle("", isOn: $preferences.useIconFilters)
                .labelsHidden()
                .tint(themeManager.current.accentColor)
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: rowMinimumHeight)
    }

    private var logoutRow: some View {
        Button {
            showLogoutConfirmation = true
        } label: {
            HStack(spacing: 12 * layoutScale) {
                SettingsRowIcon(systemImage: "rectangle.portrait.and.arrow.right", tint: .red)
                Text("çıkış yap")
                    .settingsFont(baseSize: 17, weight: .medium)
                    .foregroundColor(.red)
                Spacer()
            }
            .padding(.horizontal, horizontalPadding)
            .frame(minHeight: rowMinimumHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var fontSizeRow: some View {
        HStack(spacing: 12 * layoutScale) {
            SettingsRowIcon(systemImage: "textformat.size")
            VStack(alignment: .leading, spacing: 3 * layoutScale) {
                Text("yazı boyutu")
                    .settingsFont(baseSize: 17)
                    .foregroundColor(themeManager.current.labelColor)
                Text("başlık ve entry metinleri")
                    .settingsFont(baseSize: 12)
                    .foregroundColor(themeManager.current.dateColor)
            }
            Spacer(minLength: 4 * layoutScale)
            HStack(spacing: 4 * layoutScale) {
                fontButton(systemImage: "minus", delta: -1)
                Text("\(preferences.selectedFontSize)")
                    .settingsFont(baseSize: 15, weight: .semibold, design: .monospaced)
                    .foregroundColor(themeManager.current.labelColor)
                    .frame(minWidth: 28 * layoutScale)
                    .accessibilityLabel("\(preferences.selectedFontSize) punto")
                fontButton(systemImage: "plus", delta: 1)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: rowMinimumHeight)
    }

    private func fontButton(systemImage: String, delta: Int) -> some View {
        let nextSize = SettingsPresentationPolicy.adjustedFontSize(
            preferences.selectedFontSize,
            delta: delta
        )
        let isEnabled = nextSize != preferences.selectedFontSize
        return Button {
            preferences.selectedFontSize = nextSize
        } label: {
            Image(systemName: systemImage)
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.accentColor)
                .frame(
                    width: CGFloat(layoutMetrics.controlMinimumSize),
                    height: CGFloat(layoutMetrics.controlMinimumSize)
                )
                .background(themeManager.current.cellSecondaryColor, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.32)
        .accessibilityLabel(delta < 0 ? "yazıyı küçült" : "yazıyı büyüt")
    }

    private func navigationRow<Destination: View>(
        destination: Destination,
        icon: String,
        title: String,
        subtitle: String? = nil,
        detail: String? = nil
    ) -> some View {
        NavigationLink { destination } label: {
            SettingsNavigationRow(icon: icon, title: title, subtitle: subtitle, detail: detail)
        }
        .buttonStyle(.plain)
    }

    private func webSettingsRow(
        path: String,
        navigationTitle: String,
        icon: String,
        title: String,
        subtitle: String? = nil
    ) -> some View {
        NavigationLink {
            if let url = URL(string: preferences.baseURL + path) {
                EksiWebView(url: url)
                    .navigationTitle(navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                ErrorView(message: "sunucu adresi geçersiz", showRetry: false)
            }
        } label: {
            SettingsNavigationRow(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }

    private func externalRow(
        destination: URL,
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        Link(destination: destination) {
            SettingsNavigationRow(icon: icon, title: title, subtitle: subtitle)
        }
        .buttonStyle(.plain)
    }
}

private enum SettingsProjectLink {
    static let privacyPolicy = URL(
        string: "https://github.com/emreisik95/eksilik-os/blob/main/PRIVACY.md"
    )!
    static let support = URL(
        string: "https://github.com/emreisik95/eksilik-os/blob/main/SUPPORT.md"
    )!
}
