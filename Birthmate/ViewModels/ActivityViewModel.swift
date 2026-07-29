import Foundation

@MainActor
final class ActivityViewModel: ObservableObject {
    @Published var events: [ActivityEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let socialService: SocialService

    init(socialService: SocialService = SocialServiceProvider.shared) {
        self.socialService = socialService
    }

    var isDemoMode: Bool { socialService.usesDemoData }

    func load(authStore: AuthStore, discoverOthers: Bool) async {
        guard discoverOthers else {
            events = []
            return
        }

        guard authStore.isSignedIn || socialService.usesDemoData else {
            events = []
            return
        }

        isLoading = events.isEmpty
        defer { isLoading = false }

        do {
            if socialService.usesDemoData {
                events = try await socialService.fetchActivity(
                    auth: AuthContext(
                        session: AuthSession(
                            userID: "demo",
                            accessToken: "",
                            refreshToken: "",
                            expiresAt: .distantFuture
                        )
                    )
                )
                return
            }

            let session = try await authStore.validSession()
            events = try await socialService.fetchActivity(auth: AuthContext(session: session))
        } catch {
            if events.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }
}
