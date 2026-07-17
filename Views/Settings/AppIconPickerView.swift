import SwiftUI

struct AppIconPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var selectedIconName: String?
    @State private var iconError: String?

    private let columns = [
        GridItem(.adaptive(minimum: 138), spacing: 14),
    ]

    private let choices = [
        AppIconChoice(title: "varsayılan", iconName: nil, imageName: "AppIcon"),
        AppIconChoice(title: "açık", iconName: "AlternateIcon", imageName: "AlternateIcon@2x"),
        AppIconChoice(title: "klasik", iconName: "AlternateKlasik", imageName: "AlternateKlasik@2x"),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("ek$ilik sana benzesin")
                        .font(.title3.bold())
                        .foregroundColor(themeManager.current.labelColor)
                    Text("ana ekranda görmek istediğin uygulama ikonunu seç")
                        .font(.subheadline)
                        .foregroundColor(themeManager.current.dateColor)
                }

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(choices) { choice in
                        iconButton(choice)
                    }
                }
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("uygulama ikonu")
        .navigationBarTitleDisplayMode(.inline)
        .alert("ikon değiştirilemedi", isPresented: Binding(
            get: { iconError != nil },
            set: { if !$0 { iconError = nil } }
        )) {
            Button("tamam", role: .cancel) { }
        } message: {
            Text(iconError ?? "bilinmeyen hata")
        }
    }

    private func iconButton(_ choice: AppIconChoice) -> some View {
        let isSelected = selectedIconName == choice.iconName

        return Button {
            changeAppIcon(to: choice.iconName)
        } label: {
            VStack(spacing: 14) {
                if let image = UIImage(named: choice.imageName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 82, height: 82)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(.white.opacity(0.18), lineWidth: 1)
                        }
                        .shadow(color: .black.opacity(0.16), radius: 8, y: 4)
                }

                HStack(spacing: 6) {
                    Text(choice.title)
                        .font(.subheadline.weight(.semibold))
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                }
                .foregroundColor(isSelected
                    ? themeManager.current.backgroundColor
                    : themeManager.current.labelColor)
            }
            .frame(maxWidth: .infinity, minHeight: 142)
            .padding(14)
            .background(
                isSelected
                    ? themeManager.current.accentColor
                    : themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 22, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        isSelected
                            ? themeManager.current.accentColor
                            : themeManager.current.separatorColor.opacity(0.18),
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(choice.title) uygulama ikonu")
        .accessibilityValue(isSelected ? "seçili" : "")
    }

    private func changeAppIcon(to iconName: String?) {
        guard UIApplication.shared.supportsAlternateIcons else {
            iconError = "bu cihaz alternatif uygulama ikonlarını desteklemiyor"
            return
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            DispatchQueue.main.async {
                if let error {
                    iconError = error.localizedDescription
                } else {
                    selectedIconName = iconName
                }
            }
        }
    }
}

private struct AppIconChoice: Identifiable {
    let title: String
    let iconName: String?
    let imageName: String

    var id: String { iconName ?? "default" }
}
