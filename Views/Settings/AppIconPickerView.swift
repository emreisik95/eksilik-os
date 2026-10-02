import SwiftUI

struct AppIconPickerView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var selectedIconName: String?
    @State private var iconError: String?

    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 12),
    ]

    private let choices = AppIconPresentationPolicy.choices

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

                LazyVGrid(columns: columns, spacing: 12) {
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
            VStack(spacing: 10) {
                iconPreview(choice)

                HStack(spacing: 4) {
                    Text(choice.title)
                        .font(.footnote.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.footnote)
                }
                .foregroundColor(isSelected
                    ? themeManager.current.backgroundColor
                    : themeManager.current.labelColor)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                isSelected
                    ? themeManager.current.accentColor
                    : themeManager.current.cellPrimaryColor,
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
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

    @ViewBuilder
    private func iconPreview(_ choice: AppIconChoice) -> some View {
        if let image = UIImage(named: choice.imageName) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: 68, height: 68)
                .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 15, style: .continuous)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
        }
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
