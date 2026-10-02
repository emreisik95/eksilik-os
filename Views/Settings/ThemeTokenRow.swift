import SwiftUI
import UIKit

/// One editable palette color: swatch, system color picker (no opacity) and a hex field that
/// applies as soon as it holds six valid digits.
struct ThemeTokenRow: View {
    let key: ThemeTokenKey
    @Binding var token: ThemeColorToken
    let isHighlighted: Bool
    let onFocus: () -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var preferences: UserPreferences
    @FocusState private var isHexFocused: Bool
    @State private var hexText: String

    init(
        key: ThemeTokenKey,
        token: Binding<ThemeColorToken>,
        isHighlighted: Bool,
        onFocus: @escaping () -> Void
    ) {
        self.key = key
        _token = token
        self.isHighlighted = isHighlighted
        self.onFocus = onFocus
        _hexText = State(initialValue: token.wrappedValue.hexString)
    }

    private var metrics: SettingsLayoutMetrics {
        SettingsPresentationPolicy.layoutMetrics(fontSize: preferences.selectedFontSize)
    }

    private var isHexValid: Bool {
        ThemeColorToken(hexString: hexText) != nil
    }

    private var colorBinding: Binding<Color> {
        Binding(
            get: { token.color },
            set: { newColor in
                let updated = ThemeColorToken(color: newColor)
                if updated != token {
                    token = updated
                }
            }
        )
    }

    var body: some View {
        let scale = CGFloat(metrics.scale)
        let isInline = Self.fitsInline(scale: scale)

        VStack(alignment: .trailing, spacing: 8 * scale) {
            HStack(spacing: 12 * scale) {
                focusButton(scale: scale)
                if isInline {
                    controls(scale: scale)
                }
            }
            if !isInline {
                controls(scale: scale)
            }
        }
        .padding(.horizontal, CGFloat(metrics.horizontalPadding))
        .padding(.vertical, 10 * scale)
        .frame(minHeight: CGFloat(metrics.rowMinimumHeight))
        .background(isHighlighted ? themeManager.current.accentColor.opacity(0.14) : Color.clear)
        .overlay(alignment: .leading) {
            if isHighlighted {
                Rectangle()
                    .fill(themeManager.current.accentColor)
                    .frame(width: 3)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isHighlighted)
        .onChange(of: token) { newToken in
            if !isHexFocused || ThemeColorToken(hexString: hexText) != newToken {
                hexText = newToken.hexString
            }
        }
        .onChange(of: hexText) { text in
            if let parsed = ThemeColorToken(hexString: text), parsed != token {
                token = parsed
            }
        }
        .onChange(of: isHexFocused) { focused in
            if !focused {
                hexText = token.hexString
            }
        }
    }

    /// Large text sizes on narrow phones move the controls under the label instead of squeezing it.
    private static func fitsInline(scale: CGFloat) -> Bool {
        let available = UIScreen.main.bounds.width - 32
        let needed = 28 + 302 * scale
        return needed <= available
    }

    private func focusButton(scale: CGFloat) -> some View {
        Button(action: onFocus) {
            HStack(spacing: 12 * scale) {
                RoundedRectangle(cornerRadius: 9 * scale, style: .continuous)
                    .fill(token.color)
                    .frame(width: 34 * scale, height: 34 * scale)
                    .overlay {
                        RoundedRectangle(cornerRadius: 9 * scale, style: .continuous)
                            .stroke(themeManager.current.separatorColor.opacity(0.5), lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 2 * scale) {
                    Text(key.title)
                        .settingsFont(baseSize: 16, weight: .semibold)
                        .foregroundColor(themeManager.current.labelColor)
                    Text(key.hint)
                        .settingsFont(baseSize: 12)
                        .foregroundColor(themeManager.current.dateColor)
                        .lineLimit(2)
                }
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(key.title), \(token.hexString)")
        .accessibilityHint("önizlemede bu rengin kullanıldığı yerleri gösterir")
    }

    private func controls(scale: CGFloat) -> some View {
        HStack(spacing: 12 * scale) {
            hexField(scale: scale)
            ColorPicker(key.title, selection: colorBinding, supportsOpacity: false)
                .labelsHidden()
                .frame(width: 30 * scale, height: 30 * scale)
        }
    }

    private func hexField(scale: CGFloat) -> some View {
        TextField("#RRGGBB", text: $hexText)
            .focused($isHexFocused)
            .settingsFont(baseSize: 14, weight: .medium, design: .monospaced)
            .foregroundColor(themeManager.current.labelColor)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .keyboardType(.asciiCapable)
            .submitLabel(.done)
            .multilineTextAlignment(.center)
            .frame(width: 92 * scale)
            .padding(.vertical, 6 * scale)
            .background(
                themeManager.current.cellSecondaryColor,
                in: RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8 * scale, style: .continuous)
                    .stroke(isHexValid ? Color.clear : Color.red.opacity(0.8), lineWidth: 1)
            }
            .accessibilityLabel("\(key.title) hex kodu")
    }
}
