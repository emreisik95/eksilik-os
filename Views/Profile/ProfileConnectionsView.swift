import SwiftUI

struct ProfileConnectionsView: View {
    @StateObject private var viewModel: ProfileConnectionsViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    init(path: String, title: String) {
        _viewModel = StateObject(wrappedValue: ProfileConnectionsViewModel(path: path, title: title))
    }

    var body: some View {
        ZStack {
            themeManager.current.backgroundColor.ignoresSafeArea()

            if viewModel.isLoading && viewModel.people.isEmpty {
                SearchResultsSkeletonView()
            } else if let error = viewModel.error, viewModel.people.isEmpty {
                ErrorView(message: error) {
                    Task { await viewModel.load() }
                }
            } else if viewModel.people.isEmpty {
                EmptyStateView(message: "kimse görünmüyor")
            } else {
                connectionList
            }
        }
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    private var connectionList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(viewModel.people) { person in
                    NavigationLink(value: Route.profile(username: person.username)) {
                        connectionRow(person)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }

    private func connectionRow(_ person: ProfileConnection) -> some View {
        HStack(spacing: 13) {
            if let avatarURL = person.avatarURL {
                CachedRemoteImage(url: avatarURL, showsRetry: false)
                    .frame(width: 52, height: 52)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.secondary)
                    .frame(width: 52, height: 52)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(person.username)
                    .font(.body.weight(.semibold))
                    .foregroundColor(themeManager.current.labelColor)
                    .multilineTextAlignment(.leading)

                if person.followsYou || person.isFollowing {
                    HStack(spacing: 6) {
                        if person.followsYou {
                            relationBadge("seni takip ediyor", icon: "arrow.left")
                        }
                        if person.isFollowing {
                            relationBadge("takiptesin", icon: "checkmark")
                        }
                    }
                }
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .background(themeManager.current.cellPrimaryColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private func relationBadge(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .font(.caption2.weight(.semibold))
            .foregroundColor(themeManager.current.accentColor)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(themeManager.current.accentColor.opacity(0.12))
            .clipShape(Capsule())
    }
}
