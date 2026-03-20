import SwiftUI

struct PaginationView: View {
    let pagination: Pagination
    let onPageChange: (Int) -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        HStack(spacing: 12) {
            Button(action: { onPageChange(1) }) {
                Image(systemName: "backward.end.fill")
            }
            .disabled(!pagination.hasPreviousPage)

            Button(action: { onPageChange(pagination.currentPage - 1) }) {
                Image(systemName: "chevron.left")
            }
            .disabled(!pagination.hasPreviousPage)

            Text("\(pagination.currentPage) / \(pagination.totalPages)")
                .font(.caption)
                .foregroundColor(themeManager.current.labelColor)

            Button(action: { onPageChange(pagination.currentPage + 1) }) {
                Image(systemName: "chevron.right")
            }
            .disabled(!pagination.hasNextPage)

            Button(action: { onPageChange(pagination.totalPages) }) {
                Image(systemName: "forward.end.fill")
            }
            .disabled(!pagination.hasNextPage)
        }
        .foregroundColor(themeManager.current.accentColor)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(themeManager.current.backgroundColor)
    }
}
