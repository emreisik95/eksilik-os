import SwiftUI

struct PaginationView: View {
    let pagination: Pagination
    let onPageChange: (Int) -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: CGFloat(EntryListChromePolicy.paginationSectionSpacing)) {
            controlGroup(EntryListChromePolicy.leadingPaginationControls)

            Text("\(pagination.currentPage) / \(pagination.totalPages)")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(themeManager.current.labelColor)
                .frame(minWidth: 56, minHeight: 44)
                .background(
                    Capsule()
                        .fill(themeManager.current.cellSecondaryColor)
                )
                .accessibilityLabel("\(pagination.totalPages) sayfadan \(pagination.currentPage). sayfa")

            controlGroup(EntryListChromePolicy.trailingPaginationControls)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(themeManager.current.backgroundColor)
    }

    private func controlGroup(_ controls: [PaginationControl]) -> some View {
        HStack(spacing: CGFloat(EntryListChromePolicy.paginationControlSpacing)) {
            ForEach(controls) { control in
                paginationButton(control)
            }
        }
    }

    private func paginationButton(_ control: PaginationControl) -> some View {
        let isEnabled = control.isEnabled(in: pagination)

        return Button {
            onPageChange(control.targetPage(in: pagination))
        } label: {
            Image(systemName: control.systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(themeManager.current.accentColor)
                .frame(
                    width: CGFloat(EntryListChromePolicy.paginationButtonSize),
                    height: CGFloat(EntryListChromePolicy.paginationButtonSize)
                )
                .background(
                    Circle()
                        .fill(themeManager.current.cellSecondaryColor)
                )
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.32)
        .accessibilityLabel(control.accessibilityLabel)
    }
}
