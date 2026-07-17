import SwiftUI

struct ServerSettingsView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    @Binding var baseURL: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "network")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(themeManager.current.accentColor)
                        .frame(width: 58, height: 58)
                        .background(
                            themeManager.current.accentColor.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                        )

                    Text("bağlantı noktası")
                        .font(.title3.bold())
                        .foregroundColor(themeManager.current.labelColor)
                    Text("uygulamanın bağlanacağı ekşi sözlük sunucusunu belirler")
                        .font(.subheadline)
                        .foregroundColor(themeManager.current.dateColor)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("sunucu adresi")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(themeManager.current.dateColor)

                    TextField("https://eksisozluk.com", text: $baseURL)
                        .font(.body.monospaced())
                        .foregroundColor(themeManager.current.labelColor)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                        .submitLabel(.done)
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(
                            themeManager.current.cellSecondaryColor,
                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                        )
                }
                .padding(16)
                .background(
                    themeManager.current.cellPrimaryColor,
                    in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
                }

                Label(
                    "Değişiklik anında uygulanır. Yalnızca kullandığın sunucudan eminsen bu alanı değiştir.",
                    systemImage: "exclamationmark.triangle"
                )
                .font(.footnote)
                .foregroundColor(themeManager.current.dateColor)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    themeManager.current.cellPrimaryColor,
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
            }
            .padding(16)
        }
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .navigationTitle("sunucu")
        .navigationBarTitleDisplayMode(.inline)
    }
}
