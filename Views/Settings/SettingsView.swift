import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var preferences: UserPreferences

    @State var currentIconName: String? = UIApplication.shared.alternateIconName
    @State var showLogoutConfirmation = false

    private var sections: [SettingsSectionDescriptor] {
        SettingsPresentationPolicy.sections(isLoggedIn: session.isLoggedIn)
    }

    var layoutMetrics: SettingsLayoutMetrics {
        SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
    }

    var layoutScale: CGFloat { CGFloat(layoutMetrics.scale) }
    var rowMinimumHeight: CGFloat { CGFloat(layoutMetrics.rowMinimumHeight) }
    var horizontalPadding: CGFloat { CGFloat(layoutMetrics.horizontalPadding) }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: CGFloat(layoutMetrics.sectionSpacing)) {
                    accountHeader

                    ForEach(sections) { section in
                        settingsSection(section)
                    }

                    versionFooter
                }
                .padding(.horizontal, 16 * layoutScale)
                .padding(.top, 8 * layoutScale)
                .padding(.bottom, 32 * layoutScale)
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
            .task(id: session.username) {
                await refreshAccountAvatarIfNeeded()
            }
        }
    }

    private var accountHeader: some View {
        HStack(spacing: 14 * layoutScale) {
            Group {
                if session.isLoggedIn, let avatarURL = session.profileAvatarURL {
                    CachedRemoteImage(url: avatarURL, showsRetry: false)
                        .clipShape(Circle())
                } else {
                    ZStack {
                        Circle()
                            .fill(themeManager.current.accentColor.opacity(0.16))
                        Image(systemName: session.isLoggedIn
                            ? "person.crop.circle.fill"
                            : "person.crop.circle.badge.questionmark")
                            .font(.system(size: 31 * min(1.3, max(1, layoutScale)), weight: .medium))
                            .foregroundColor(themeManager.current.accentColor)
                    }
                }
            }
            .frame(
                width: 58 * min(1.3, max(1, layoutScale)),
                height: 58 * min(1.3, max(1, layoutScale))
            )
            .accessibilityLabel(session.isLoggedIn ? "profil fotoğrafı" : "misafir profili")

            VStack(alignment: .leading, spacing: 5 * layoutScale) {
                Text(session.isLoggedIn ? (session.username ?? "ekşi sözlük hesabı") : "misafir modundasın")
                    .settingsFont(baseSize: 17, weight: .semibold)
                    .foregroundColor(themeManager.current.labelColor)
                    .lineLimit(1)

                Text(accountSubtitle)
                    .settingsFont(baseSize: 15)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(2)
            }

            Spacer(minLength: 8 * layoutScale)

            Image(systemName: session.isLoggedIn ? "checkmark.seal.fill" : "lock.open")
                .font(.title3)
                .foregroundColor(themeManager.current.accentColor)
                .accessibilityHidden(true)
        }
        .padding(CGFloat(layoutMetrics.cardPadding))
        .background(
            LinearGradient(
                colors: [
                    themeManager.current.accentColor.opacity(0.14),
                    themeManager.current.cellPrimaryColor,
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(
                cornerRadius: CGFloat(layoutMetrics.cornerRadius) + 4,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: CGFloat(layoutMetrics.cornerRadius) + 4,
                style: .continuous
            )
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

    @MainActor
    private func refreshAccountAvatarIfNeeded() async {
        guard session.isLoggedIn,
              session.profileAvatarURL == nil,
              let username = session.username,
              !username.isEmpty else { return }
        _ = try? await UserService().fetchProfile(username: username)
    }

    private func settingsSection(_ section: SettingsSectionDescriptor) -> some View {
        VStack(alignment: .leading, spacing: 10 * layoutScale) {
            Label(section.kind.title, systemImage: section.kind.systemImage)
                .settingsFont(baseSize: 15, weight: .bold)
                .foregroundColor(themeManager.current.labelColor)
                .padding(.horizontal, 4 * layoutScale)

            VStack(spacing: 0) {
                ForEach(Array(section.items.enumerated()), id: \.element.id) { index, item in
                    if index > 0 {
                        Divider()
                            .overlay(themeManager.current.separatorColor.opacity(0.22))
                            .padding(.leading, rowMinimumHeight)
                    }
                    settingsItem(item)
                }
            }
            .background(
                themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(
                    cornerRadius: CGFloat(layoutMetrics.cornerRadius),
                    style: .continuous
                )
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: CGFloat(layoutMetrics.cornerRadius),
                    style: .continuous
                )
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
            }
        }
    }

    var currentIconTitle: String {
        AppIconPresentationPolicy.title(for: currentIconName)
    }

    private var versionFooter: some View {
        VStack(spacing: 5 * layoutScale) {
            Text("ek$ilik")
                .settingsFont(baseSize: 13, weight: .semibold)
            Text("sürüm \(appVersion)")
                .settingsFont(baseSize: 11)
            Text("ekşi sözlük ile resmi bağlantısı yoktur")
                .settingsFont(baseSize: 11)
        }
        .foregroundColor(themeManager.current.dateColor)
        .frame(maxWidth: .infinity)
        .padding(.top, 4 * layoutScale)
        .accessibilityElement(children: .combine)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "2.0.0"
    }
}

struct SettingsNavigationRow: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let icon: String
    let title: String
    var subtitle: String?
    var detail: String?
    var isAccented = false

    private var metrics: SettingsLayoutMetrics {
        SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
    }

    private var scale: CGFloat { CGFloat(metrics.scale) }

    var body: some View {
        HStack(spacing: 12 * scale) {
            SettingsRowIcon(systemImage: icon)

            VStack(alignment: .leading, spacing: 3 * scale) {
                Text(title)
                    .settingsFont(baseSize: 17, weight: isAccented ? .semibold : .regular)
                    .foregroundColor(isAccented
                        ? themeManager.current.accentColor
                        : themeManager.current.labelColor)
                if let subtitle {
                    Text(subtitle)
                        .settingsFont(baseSize: 12)
                        .foregroundColor(themeManager.current.dateColor)
                        .lineLimit(scale > 1.2 ? 2 : 1)
                }
            }

            Spacer(minLength: 8 * scale)

            if let detail {
                Text(detail)
                    .settingsFont(baseSize: 15)
                    .foregroundColor(themeManager.current.dateColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundColor(themeManager.current.dateColor.opacity(0.65))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, CGFloat(metrics.horizontalPadding))
        .frame(minHeight: CGFloat(metrics.rowMinimumHeight))
        .contentShape(Rectangle())
    }
}

struct SettingsRowIcon: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences

    let systemImage: String
    var tint: Color?

    var body: some View {
        let color = tint ?? themeManager.current.accentColor
        let metrics = SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
        let scale = CGFloat(metrics.scale)
        let containerSize = CGFloat(metrics.iconContainerSize)

        Image(systemName: systemImage)
            .font(.system(size: 16 * min(1.3, max(1, scale)), weight: .semibold))
            .foregroundColor(color)
            .frame(width: containerSize, height: containerSize)
            .background(
                color.opacity(0.13),
                in: RoundedRectangle(cornerRadius: 10 * min(1.25, max(1, scale)))
            )
            .accessibilityHidden(true)
    }
}
