import SwiftUI

struct LoadingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isAnimating = false

    var body: some View {
        List {
            ForEach(0..<12, id: \.self) { i in
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        SkeletonRect(width: widths[i % widths.count])
                        SkeletonRect(width: subWidths[i % subWidths.count])
                            .opacity(0.5)
                    }
                    Spacer()
                    SkeletonRect(width: 30)
                        .opacity(0.7)
                }
                .padding(.vertical, 4)
                .listRowBackground(
                    i % 2 == 0
                    ? themeManager.current.cellPrimaryColor
                    : themeManager.current.cellSecondaryColor
                )
            }
        }
        .listStyle(.plain)
        .opacity(isAnimating ? 0.4 : 1.0)
        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isAnimating)
        .onAppear { isAnimating = true }
    }

    private let widths: [CGFloat] = [200, 160, 240, 180, 220, 140, 260, 190, 170, 230, 150, 210]
    private let subWidths: [CGFloat] = [80, 60, 100, 70, 90, 110, 75, 95, 65, 85, 105, 55]
}

private struct SkeletonRect: View {
    let width: CGFloat
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(themeManager.current.labelColor.opacity(0.15))
            .frame(width: width, height: 14)
    }
}
