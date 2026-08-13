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
    @State private var pageText: String
    @FocusState private var isInputFocused: Bool

    init(pagination: Pagination, onSelect: @escaping (Int) -> Void) {
        self.pagination = pagination
        self.onSelect = onSelect
        _pageText = State(initialValue: String(pagination.currentPage))
    }

    private var selectedPage: Int? {
        PaginationSelectionPolicy.page(from: pageText, totalPages: pagination.totalPages)
    }

    private var quickPages: [Int] {
        PaginationSelectionPolicy.quickPages(
            currentPage: pagination.currentPage,
            totalPages: pagination.totalPages
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("sayfaya git")
                    .font(.title2.bold())
                    .foregroundColor(themeManager.current.labelColor)
                Text("toplam \(pagination.totalPages) sayfa")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "number")
                        .foregroundColor(themeManager.current.accentColor)
                    TextField("sayfa", text: $pageText)
                        .keyboardType(.numberPad)
                        .focused($isInputFocused)
                        .font(.title3.weight(.semibold).monospacedDigit())
                        .foregroundColor(themeManager.current.labelColor)
                        .accessibilityLabel("sayfa numarası")
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(
                    themeManager.current.cellSecondaryColor,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )

                Button("git") {
                    submitManualPage()
                }
                .font(.body.weight(.bold))
                .foregroundColor(themeManager.current.backgroundColor)
                .frame(width: 70, height: 52)
                .background(
                    themeManager.current.accentColor,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                )
                .disabled(selectedPage == nil)
                .opacity(selectedPage == nil ? 0.4 : 1)
            }

            if !pageText.isEmpty, selectedPage == nil {
                Label("yalnızca sayfa numarası yaz", systemImage: "exclamationmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("hızlı seçim")
                .font(.headline)
                .foregroundColor(themeManager.current.labelColor)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                ForEach(quickPages, id: \.self) { page in
                    Button {
                        select(page)
                    } label: {
                        Text("\(page)")
                            .font(.body.weight(page == pagination.currentPage ? .bold : .medium).monospacedDigit())
                            .foregroundColor(
                                page == pagination.currentPage
                                    ? themeManager.current.backgroundColor
                                    : themeManager.current.labelColor
                            )
                            .frame(maxWidth: .infinity, minHeight: 46)
                            .background(
                                page == pagination.currentPage
                                    ? themeManager.current.accentColor
                                    : themeManager.current.cellSecondaryColor,
                                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(page). sayfa")
                    .accessibilityValue(page == pagination.currentPage ? "seçili" : "")
                }
            }

            Spacer(minLength: 0)
        }
        .padding(20)
        .background(themeManager.current.backgroundColor.ignoresSafeArea())
        .onSubmit(submitManualPage)
    }

    private func submitManualPage() {
        guard let selectedPage else { return }
        select(selectedPage)
    }

    private func select(_ page: Int) {
        isInputFocused = false
        onSelect(page)
        dismiss()
    }
}
