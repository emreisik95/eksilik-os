import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var session: SessionManager
    @EnvironmentObject private var preferences: UserPreferences

    @State private var currentIconName: String? = UIApplication.shared.alternateIconName
    @State private var showLogoutConfirmation = false

    private var sections: [SettingsSectionDescriptor] {
        SettingsPresentationPolicy.sections(isLoggedIn: session.isLoggedIn)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 22) {
                    accountHeader

                    ForEach(sections) { section in
                        settingsSection(section)
                    }

                    versionFooter
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .background(themeManager.current.backgroundColor.ignoresSafeArea())
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(themeManager.current.backgroundColor, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .tint(themeManager.current.accentColor)
            .confirmationDialog(
                "hesaptan çıkılsın mı?",
                isPresented: $showLogoutConfirmation,
                titleVisibility: .visible
            ) {
                Button("çıkış yap", role: .destructive) {
                    session.logout()
                }
                Button("vazgeç", role: .cancel) { }
            } message: {
                Text("Bu cihazdaki ekşi sözlük oturumu kapatılacak.")
            }
        }
    }

    private var accountHeader: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(themeManager.current.accentColor.opacity(0.16))
                Image(systemName: session.isLoggedIn
                    ? "person.crop.circle.fill"
                    : "person.crop.circle.badge.questionmark")
                    .font(.system(size: 31, weight: .medium))
                    .foregroundColor(themeManager.current.accentColor)
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 5) {
                Text(session.isLoggedIn ? (session.username ?? "ekşi sözlük hesabı") : "misafir modundasın")
                    .font(.headline)
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(1)

                Text(accountSubtitle)
                    .font(.subheadline)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(2)
            }

            Spacer(minLength: 8)

            Image(systemName: session.isLoggedIn ? "checkmark.seal.fill" : "lock.open")
                .font(.title3)
                .foregroundColor(themeManager.current.accentColor)
                .accessibilityHidden(true)
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [
                    themeManager.current.accentColor.opacity(0.14),
                    themeManager.current.cellPrimaryColor,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(themeManager.current.accentColor.opacity(0.16), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }

    private var accountSubtitle: String {
        guard session.isLoggedIn else {
            return "hesabını bağlayarak kişisel özellikleri aç"
        }
        return session.isPaidMember ? "reklamsız üyelik etkin" : "oturum açık"
    }

    private func settingsSection(_ section: SettingsSectionDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(section.kind.title, systemImage: section.kind.systemImage)
                .font(.subheadline.weight(.bold))
                .foregroundColor(themeManager.current.labelColor)
                .padding(.horizontal, 4)

            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .overlay(themeManager.current.separatorColor.opacity(0.22))
                            .padding(.leading, 62)
                    }
                    settingsItem(item)
                }
            }
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
            }
        }
    }

    @ViewBuilder
    private func settingsItem(_ item: SettingsItem) -> some View {
        switch item {
        case .theme:
            NavigationLink {
                ThemePickerView()
            } label: {
                SettingsNavigationRow(
                    icon: "circle.lefthalf.filled",
                    title: "tema",
                    detail: themeManager.current.name
                )
            }
            .buttonStyle(.plain)

        case .entryLayout:
            NavigationLink {
                EntryLayoutPickerView()
            } label: {
                SettingsNavigationRow(
                    icon: "rectangle.split.3x1",
                    title: "entry görünümü",
                    detail: preferences.entryLayoutStyle.name
                )
            }
            .buttonStyle(.plain)

        case .fontSize:
            fontSizeRow

        case .filterStyle:
            HStack(spacing: 12) {
                SettingsRowIcon(systemImage: "line.3.horizontal.decrease.circle")
                VStack(alignment: .leading, spacing: 3) {
                    Text("filtre görünümü")
                        .font(.body)
                        .foregroundColor(themeManager.current.labelColor)
                    Text("metin yerine sade ikonlar kullan")
                        .font(.caption)
                        .foregroundColor(themeManager.current.dateColor)
                }
                Spacer(minLength: 8)
                Toggle("", isOn: $preferences.useIconFilters)
                    .labelsHidden()
                    .tint(themeManager.current.accentColor)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 62)

        case .appIcon:
            NavigationLink {
                AppIconPickerView(selectedIconName: $currentIconName)
            } label: {
                SettingsNavigationRow(
                    icon: "app.dashed",
                    title: "uygulama ikonu",
                    detail: currentIconTitle
                )
            }
            .buttonStyle(.plain)

        case .homeNavigation:
            NavigationLink {
                HomeNavigationStylePickerView()
            } label: {
                SettingsNavigationRow(
                    icon: "rectangle.bottomthird.inset.filled",
                    title: "navigasyon görünümü",
                    detail: preferences.homeNavigationStyle.name
                )
            }
            .buttonStyle(.plain)

        case .homeTabs:
            NavigationLink {
                TabCustomizationView()
            } label: {
                SettingsNavigationRow(
                    icon: "square.grid.2x2",
                    title: "sekmeleri düzenle",
                    subtitle: "sırala, göster veya gizle"
                )
            }
            .buttonStyle(.plain)

        case .offlineLibrary:
            NavigationLink {
                OfflineLibraryView()
            } label: {
                SettingsNavigationRow(
                    icon: "arrow.down.circle",
                    title: "çevrimdışı okuma",
                    subtitle: "indirilen başlıkları yönet"
                )
            }
            .buttonStyle(.plain)

        case .blockedTopics:
            NavigationLink {
                BlockedTopicsView()
            } label: {
                SettingsNavigationRow(
                    icon: "eye.slash",
                    title: "engellenen başlıklar",
                    subtitle: "içerik filtrelerini düzenle"
                )
            }
            .buttonStyle(.plain)

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
            NavigationLink {
                if let url = URL(string: "\(preferences.baseURL)/ayarlar/tercihler") {
                    EksiWebView(url: url)
                        .navigationTitle("tercihler")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    ErrorView(message: "sunucu adresi geçersiz", showRetry: false)
                }
            } label: {
                SettingsNavigationRow(
                    icon: "person.text.rectangle",
                    title: "hesap tercihleri",
                    subtitle: "web hesabındaki seçenekler"
                )
            }
            .buttonStyle(.plain)

        case .trackingAndBlocks:
            NavigationLink {
                if let url = URL(string: "\(preferences.baseURL)/takip-engellenmis") {
                    EksiWebView(url: url)
                        .navigationTitle("takip / engellenmişler")
                        .navigationBarTitleDisplayMode(.inline)
                } else {
                    ErrorView(message: "sunucu adresi geçersiz", showRetry: false)
                }
            } label: {
                SettingsNavigationRow(
                    icon: "person.2.slash",
                    title: "takip ve engellenmişler"
                )
            }
            .buttonStyle(.plain)

        case .logout:
            Button {
                showLogoutConfirmation = true
            } label: {
                HStack(spacing: 12) {
                    SettingsRowIcon(systemImage: "rectangle.portrait.and.arrow.right", tint: .red)
                    Text("çıkış yap")
                        .font(.body.weight(.medium))
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 62)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

        case .privacyPolicy:
            Link(destination: ProjectLink.privacyPolicy) {
                SettingsNavigationRow(
                    icon: "hand.raised",
                    title: L10n.Settings.privacyPolicy,
                    subtitle: "verilerin nasıl işlendiğini gör"
                )
            }
            .buttonStyle(.plain)

        case .support:
            Link(destination: ProjectLink.support) {
                SettingsNavigationRow(
                    icon: "questionmark.bubble",
                    title: L10n.Settings.support,
                    subtitle: "yardım al veya sorun bildir"
                )
            }
            .buttonStyle(.plain)

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

    private var fontSizeRow: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemImage: "textformat.size")

            VStack(alignment: .leading, spacing: 3) {
                Text("yazı boyutu")
                    .font(.body)
                    .foregroundColor(themeManager.current.labelColor)
                Text("başlık ve entry metinleri")
                    .font(.caption)
                    .foregroundColor(themeManager.current.dateColor)
            }

            Spacer(minLength: 4)

            HStack(spacing: 4) {
                fontButton(systemImage: "minus", delta: -1)

                Text("\(preferences.selectedFontSize)")
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundColor(themeManager.current.labelColor)
                    .frame(minWidth: 28)
                    .accessibilityLabel("\(preferences.selectedFontSize) punto")

                fontButton(systemImage: "plus", delta: 1)
            }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
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
                .frame(width: 44, height: 44)
                .background(
                    themeManager.current.cellSecondaryColor,
                    in: Circle()
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.32)
        .accessibilityLabel(delta < 0 ? "yazıyı küçült" : "yazıyı büyüt")
    }

    private var currentIconTitle: String {
        switch currentIconName {
        case "AlternateIcon": return "açık"
        case "AlternateKlasik": return "klasik"
        default: return "varsayılan"
        }
    }

    private var versionFooter: some View {
        VStack(spacing: 5) {
            Text("ek$ilik")
                .font(.footnote.weight(.semibold))
            Text("sürüm \(appVersion)")
                .font(.caption2)
            Text("ekşi sözlük ile resmi bağlantısı yoktur")
                .font(.caption2)
        }
        .foregroundColor(themeManager.current.dateColor)
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0.0"
    }
}

private enum ProjectLink {
    static let privacyPolicy = URL(
        string: "https://github.com/emreisik95/eksilik-os/blob/main/PRIVACY.md"
    )!
    static let support = URL(
        string: "https://github.com/emreisik95/eksilik-os/blob/main/SUPPORT.md"
    )!
}

private struct SettingsNavigationRow: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let icon: String
    let title: String
    var subtitle: String?
    var detail: String?
    var isAccented = false

    var body: some View {
        HStack(spacing: 12) {
            SettingsRowIcon(systemImage: icon)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.body.weight(isAccented ? .semibold : .regular))
                    .foregroundColor(isAccented
                        ? themeManager.current.accentColor
                        : themeManager.current.labelColor)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(themeManager.current.dateColor)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 8)

            if let detail {
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.dateColor.opacity(0.65))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 62)
        .contentShape(Rectangle())
    }
}

private struct SettingsRowIcon: View {
    @EnvironmentObject private var themeManager: ThemeManager

    let systemImage: String
    var tint: Color?

    var body: some View {
        let color = tint ?? themeManager.current.accentColor

        Image(systemName: systemImage)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(color)
            .frame(width: 36, height: 36)
            .background(color.opacity(0.13), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)
    }
}
