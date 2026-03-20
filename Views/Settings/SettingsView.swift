import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var session: SessionManager
    @EnvironmentObject var preferences: UserPreferences
    @State private var currentIconName: String? = UIApplication.shared.alternateIconName

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.Settings.appearance) {
                    NavigationLink(L10n.Settings.theme) {
                        ThemePickerView()
                    }

                    Stepper(L10n.Settings.fontSize(preferences.selectedFontSize), value: $preferences.selectedFontSize, in: 10...24)
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                Section("uygulama ikonu") {
                    iconRow(title: "varsayilan", iconName: nil, imageName: "AppIcon")
                    iconRow(title: "açık", iconName: "AlternateIcon", imageName: "AlternateIcon@2x")
                    iconRow(title: "klasik", iconName: "AlternateKlasik", imageName: "AlternateKlasik@2x")
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                Section(L10n.Settings.content) {
                    NavigationLink(L10n.Settings.blockedTopics) {
                        BlockedTopicsView()
                    }
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                Section("ana sayfa sekmeleri") {
                    NavigationLink("sekmeleri düzenle") {
                        TabCustomizationView()
                    }

                    Picker("sekme çubuğu konumu", selection: $preferences.homeTabBarPosition) {
                        Text("üstte").tag("top")
                        Text("altta").tag("bottom")
                    }
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                Section("gelişmiş") {
                    HStack {
                        Text("sunucu adresi")
                        Spacer()
                        TextField("https://eksisozluk.com", text: $preferences.baseURL)
                            .multilineTextAlignment(.trailing)
                            .foregroundColor(.gray)
                            .font(.caption)
                    }
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)

                if !session.isLoggedIn {
                    Section {
                        NavigationLink(L10n.Settings.login) {
                            LoginView()
                        }
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                } else {
                    Section("hesap") {
                        NavigationLink("tercihler") {
                            EksiWebView(url: URL(string: "\(preferences.baseURL)/ayarlar/tercihler")!)
                                .navigationTitle("tercihler")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                        NavigationLink("takip / engellenmişler") {
                            EksiWebView(url: URL(string: "\(preferences.baseURL)/takip-engellenmis")!)
                                .navigationTitle("takip / engellenmişler")
                                .navigationBarTitleDisplayMode(.inline)
                        }
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)

                    Section {
                        Button(L10n.Settings.logout) {
                            session.logout()
                        }
                        .foregroundColor(.red)
                    }
                    .listRowBackground(themeManager.current.cellPrimaryColor)
                }

                Section(L10n.Settings.about) {
                    HStack {
                        Text(L10n.Settings.version)
                        Spacer()
                        Text("2.0")
                            .foregroundColor(.gray)
                    }
                }
                .listRowBackground(themeManager.current.cellPrimaryColor)
            }
            .listStyle(.insetGrouped)
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.inline)
            .background(themeManager.current.backgroundColor)
            .scrollContentBackground(.hidden)
        }
    }

    @ViewBuilder
    private func iconRow(title: String, iconName: String?, imageName: String) -> some View {
        Button {
            changeAppIcon(to: iconName)
        } label: {
            HStack(spacing: 12) {
                if let img = UIImage(named: imageName) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
                Text(title)
                    .foregroundColor(themeManager.current.labelColor)
                Spacer()
                if currentIconName == iconName {
                    Image(systemName: "checkmark")
                        .foregroundColor(themeManager.current.accentColor)
                }
            }
        }
    }

    private func changeAppIcon(to iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else { return }
        UIApplication.shared.setAlternateIconName(iconName) { error in
            if error == nil {
                currentIconName = iconName
            }
        }
    }
}
