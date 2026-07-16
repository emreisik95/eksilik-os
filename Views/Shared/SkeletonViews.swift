import SwiftUI

struct StableSkeletonBlock: View {
    @EnvironmentObject private var themeManager: ThemeManager
    var cornerRadius: CGFloat = 4

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(themeManager.current.labelColor.opacity(0.14))
    }
}

struct FractionalSkeletonBar: View {
    let fraction: Double
    var height: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            StableSkeletonBlock()
                .frame(width: proxy.size.width * min(max(fraction, 0), 1), height: height)
        }
        .frame(height: height)
    }
}

private struct StableSkeletonPulse: ViewModifier {
    @State private var isDimmed = false

    func body(content: Content) -> some View {
        content
            .opacity(isDimmed ? 0.48 : 1)
            .animation(.easeInOut(duration: 0.85).repeatForever(autoreverses: true), value: isDimmed)
            .onAppear { isDimmed = true }
    }
}

extension View {
    fileprivate func stableSkeletonPulse() -> some View {
        modifier(StableSkeletonPulse())
    }
}

struct TopicListSkeletonView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        List {
            ForEach(0..<12, id: \.self) { index in
                HStack(spacing: 12) {
                    FractionalSkeletonBar(fraction: SkeletonLayout.topicTitleFraction(row: index))
                    StableSkeletonBlock(cornerRadius: 10)
                        .frame(width: 36, height: 22)
                }
                .padding(.vertical, 2)
                .listRowBackground(
                    index.isMultiple(of: 2)
                    ? themeManager.current.cellPrimaryColor
                    : themeManager.current.cellSecondaryColor
                )
            }
        }
        .listStyle(.plain)
        .accessibilityHidden(true)
        .stableSkeletonPulse()
    }
}

struct EntryListSkeletonView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        List {
            ForEach(0..<5, id: \.self) { index in
                VStack(alignment: .leading, spacing: 10) {
                    FractionalSkeletonBar(fraction: 0.96, height: 12)
                    FractionalSkeletonBar(fraction: SkeletonLayout.entryLineFraction(row: index), height: 12)
                    HStack(spacing: 8) {
                        StableSkeletonBlock(cornerRadius: 10)
                            .frame(width: 20, height: 20)
                        StableSkeletonBlock()
                            .frame(width: 80, height: 10)
                        Spacer()
                        StableSkeletonBlock()
                            .frame(width: 100, height: 10)
                    }
                }
                .padding(.vertical, 6)
                .listRowBackground(themeManager.current.cellPrimaryColor)
            }
        }
        .listStyle(.plain)
        .accessibilityHidden(true)
        .stableSkeletonPulse()
    }
}

struct ProfileSkeletonView: View {
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        StableSkeletonBlock().frame(width: 150, height: 24)
                        StableSkeletonBlock().frame(width: 210, height: 14)
                        StableSkeletonBlock().frame(width: 120, height: 12)
                    }
                    Spacer()
                    StableSkeletonBlock(cornerRadius: 35).frame(width: 70, height: 70)
                }
                .padding(16)

                Divider().overlay(themeManager.current.separatorColor)

                HStack(spacing: 22) {
                    ForEach(0..<4, id: \.self) { index in
                        StableSkeletonBlock()
                            .frame(width: index == 3 ? 72 : 58, height: 14)
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 44)

                Divider().overlay(themeManager.current.separatorColor)

                VStack(spacing: 0) {
                    ForEach(0..<5, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 9) {
                            FractionalSkeletonBar(fraction: 0.54, height: 13)
                            FractionalSkeletonBar(fraction: SkeletonLayout.profileLineFraction(row: index), height: 12)
                            FractionalSkeletonBar(fraction: 0.68, height: 12)
                            HStack {
                                StableSkeletonBlock().frame(width: 70, height: 10)
                                Spacer()
                                StableSkeletonBlock().frame(width: 90, height: 10)
                            }
                        }
                        .padding(16)
                        Divider().overlay(themeManager.current.separatorColor)
                    }
                }
            }
        }
        .accessibilityHidden(true)
        .stableSkeletonPulse()
    }
}
