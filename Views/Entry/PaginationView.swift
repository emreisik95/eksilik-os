import SwiftUI

struct PaginationView: View {
    let pagination: Pagination
    let onPageChange: (Int) -> Void
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isPagePickerPresented = false

    var body: some View {
        HStack(spacing: CGFloat(EntryListChromePolicy.paginationSectionSpacing)) {
            controlGroup(EntryListChromePolicy.leadingPaginationControls)

            Button {
                isPagePickerPresented = true
            } label: {
                HStack(spacing: 5) {
                    Text("\(pagination.currentPage) / \(pagination.totalPages)")
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9, weight: .bold))
                }
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundColor(themeManager.current.labelColor)
                .padding(.horizontal, 10)
                .frame(minHeight: 32)
                .background(
                    Capsule()
                        .fill(themeManager.current.cellSecondaryColor)
                )
                .frame(minHeight: CGFloat(EntryListChromePolicy.paginationTouchTargetSize))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(pagination.totalPages) sayfadan \(pagination.currentPage). sayfa")
            .accessibilityHint("sayfa seçiciyi açar")

            controlGroup(EntryListChromePolicy.trailingPaginationControls)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .frame(maxWidth: .infinity)
        .background(themeManager.current.backgroundColor)
        .sheet(isPresented: $isPagePickerPresented) {
            PagePickerSheet(pagination: pagination) { page in
                guard page != pagination.currentPage else { return }
                onPageChange(page)
            }
            .presentationDetents([.height(430), .medium])
            .presentationDragIndicator(.visible)
        }
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
                .font(.system(
                    size: CGFloat(EntryListChromePolicy.paginationIconSize),
                    weight: .semibold
                ))
                .foregroundColor(themeManager.current.accentColor)
                .frame(
                    width: CGFloat(EntryListChromePolicy.paginationVisualButtonSize),
                    height: CGFloat(EntryListChromePolicy.paginationVisualButtonSize)
                )
                .background(
                    Circle()
                        .fill(themeManager.current.cellSecondaryColor)
                )
                .frame(
                    width: CGFloat(EntryListChromePolicy.paginationTouchTargetSize),
                    height: CGFloat(EntryListChromePolicy.paginationTouchTargetSize)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.32)
        .accessibilityLabel(control.accessibilityLabel)
    }
}

private struct PagePickerSheet: View {
    let pagination: Pagination
    let onSelect: (Int) -> Void

    @EnvironmentObject private var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPage: Int

    init(pagination: Pagination, onSelect: @escaping (Int) -> Void) {
        self.pagination = pagination
        self.onSelect = onSelect
        _selectedPage = State(initialValue: PaginationSelectionPolicy.clampedPage(
            pagination.currentPage,
            totalPages: pagination.totalPages
        ))
    }

    private var anchorPages: [Int] {
        PaginationSelectionPolicy.anchorPages(
            currentPage: pagination.currentPage,
            totalPages: pagination.totalPages
        )
    }

    private var pageRange: ClosedRange<Int> {
        1...max(1, pagination.totalPages)
    }

    var body: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("sayfayı kaydır")
                        .font(.title2.bold())
                        .foregroundColor(themeManager.current.labelColor)
                    Text("1–\(max(1, pagination.totalPages)) arasında seç")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundColor(themeManager.current.labelColor)
                        .frame(width: 36, height: 36)
                        .background(themeManager.current.cellSecondaryColor, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("sayfa seçiciyi kapat")
            }

            HStack(spacing: 6) {
                ForEach(anchorPages, id: \.self) { page in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedPage = page
                        }
                    } label: {
                        VStack(spacing: 2) {
                            Text(anchorLabel(for: page))
                                .font(.caption2.weight(.semibold))
                            Text("\(page)")
                                .font(.subheadline.bold().monospacedDigit())
                        }
                        .foregroundColor(
                            selectedPage == page
                                ? themeManager.current.backgroundColor
                                : themeManager.current.labelColor
                        )
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(
                            selectedPage == page
                                ? themeManager.current.accentColor
                                : themeManager.current.cellSecondaryColor,
                            in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(anchorLabel(for: page)), \(page). sayfa")
                }
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(themeManager.current.cellPrimaryColor)

                Picker("sayfa", selection: $selectedPage) {
                    ForEach(pageRange, id: \.self) { page in
                        Text("\(page). sayfa")
                            .font(.title3.weight(.semibold).monospacedDigit())
                            .tag(page)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 168)
                .clipped()
                .tint(themeManager.current.accentColor)
                .accessibilityValue("\(selectedPage), toplam \(max(1, pagination.totalPages))")
            }
            .frame(height: 172)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(themeManager.current.separatorColor.opacity(0.18), lineWidth: 1)
            }

            Button {
                select(selectedPage)
            } label: {
                HStack(spacing: 8) {
                    Text("\(selectedPage). sayfaya git")
                        .monospacedDigit()
                    Image(systemName: "arrow.right")
                }
                .font(.body.weight(.bold))
                .foregroundColor(themeManager.current.backgroundColor)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(
                    themeManager.current.accentColor,
                    in: RoundedRectangle(cornerRadius: 15, style: .continuous)
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint("seçilen sayfayı açar")
        }
        .padding(20)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
    }

    private func anchorLabel(for page: Int) -> String {
        if page == pagination.currentPage { return "şu an" }
        if page == 1 { return "ilk" }
        return "son"
    }

    private func select(_ page: Int) {
        let page = PaginationSelectionPolicy.clampedPage(page, totalPages: pagination.totalPages)
        if page != pagination.currentPage {
            onSelect(page)
        }
        dismiss()
    }
}
