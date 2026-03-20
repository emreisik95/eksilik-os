import SwiftUI

struct FavoriteUsersView: View {
    let entryId: String

    var body: some View {
        Text(L10n.Entry.favoriteUsers(id: entryId))
            .navigationTitle(L10n.Entry.favorites)
    }
}
