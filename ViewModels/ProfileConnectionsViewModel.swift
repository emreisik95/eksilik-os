import Foundation

@MainActor
final class ProfileConnectionsViewModel: ObservableObject {
    @Published var people: [ProfileConnection] = []
    @Published var isLoading = false
    @Published var error: String?

    let path: String
    let title: String
    private let userService = UserService()

    init(path: String, title: String) {
        self.path = path
        self.title = title
    }

    func load() async {
        guard people.isEmpty, !isLoading else { return }
        isLoading = true
        error = nil
        defer { isLoading = false }

        do {
            people = try await userService.fetchProfileConnections(path: path)
        } catch {
            self.error = error.localizedDescription
        }
    }
}
