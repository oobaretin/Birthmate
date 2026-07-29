import Foundation

@MainActor
final class CommunityViewModel: ObservableObject {
    @Published var members: [CommunityMember] = []
    @Published var friendships: [Friendship] = []
    @Published var pendingRequests: [Friendship] = []
    @Published var activity: [ActivityEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isDemoMode = false
    @Published var lastSyncedAt: Date?
    @Published var demoSentRequestIDs: Set<String> = []

    private let communityService: CommunityService
    private let socialService: SocialService

    init(
        communityService: CommunityService = CommunityServiceProvider.shared,
        socialService: SocialService = SocialServiceProvider.shared
    ) {
        self.communityService = communityService
        self.socialService = socialService
        isDemoMode = communityService.usesDemoData
    }

    func refresh(
        month: Int,
        day: Int,
        profile: ProfileStore,
        authStore: AuthStore
    ) async {
        errorMessage = nil

        guard profile.canBrowseCommunity else {
            members = []
            friendships = []
            pendingRequests = []
            activity = []
            return
        }

        isLoading = members.isEmpty
        defer { isLoading = false }

        do {
            let auth = try await resolvedAuth(authStore: authStore, profile: profile)
            try await syncOwnProfile(month: month, day: day, profile: profile, auth: auth)
            members = try await communityService.fetchMembers(
                month: month,
                day: day,
                excludingUserID: auth.userID,
                auth: auth
            )
            friendships = try await socialService.fetchFriendships(auth: auth)
            pendingRequests = friendships.filter { $0.isPending && $0.addresseeID == auth.userID }
            activity = try await socialService.fetchActivity(auth: auth)
            lastSyncedAt = Date()
        } catch {
            if members.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
    }

    func syncOwnProfile(
        month: Int,
        day: Int,
        profile: ProfileStore,
        authStore: AuthStore
    ) async throws {
        let auth = try await resolvedAuth(authStore: authStore, profile: profile)
        try await syncOwnProfile(month: month, day: day, profile: profile, auth: auth)
    }

    func syncOwnProfile(
        month: Int,
        day: Int,
        profile: ProfileStore,
        auth: AuthContext
    ) async throws {
        if profile.isDiscoverable {
            try await communityService.syncProfile(
                displayName: profile.sanitizedDisplayName(),
                month: month,
                day: day,
                isDiscoverable: true,
                famousTwinName: profile.famousTwinName,
                famousTwinWikiTitle: profile.famousTwinWikiTitle,
                auth: auth
            )
        } else {
            try await communityService.removeProfile(auth: auth)
        }
    }

    func sendFriendRequest(to member: CommunityMember, authStore: AuthStore, profile: ProfileStore) async {
        if communityService.usesDemoData {
            demoSentRequestIDs.insert(member.id)
            return
        }

        do {
            let auth = try await resolvedAuth(authStore: authStore, profile: profile)
            try await socialService.sendFriendRequest(to: member.id, auth: auth)
            friendships = try await socialService.fetchFriendships(auth: auth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToFriendRequest(_ friendship: Friendship, accept: Bool, authStore: AuthStore, profile: ProfileStore) async {
        do {
            let auth = try await resolvedAuth(authStore: authStore, profile: profile)
            try await socialService.respondToFriendRequest(id: friendship.id, accept: accept, auth: auth)
            friendships = try await socialService.fetchFriendships(auth: auth)
            pendingRequests = friendships.filter { $0.isPending && $0.addresseeID == auth.userID }
            activity = try await socialService.fetchActivity(auth: auth)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggleFavorite(_ item: OnThisDayItem, profile: ProfileStore, authStore: AuthStore) async {
        profile.toggleFavorite(item)
        guard !socialService.usesDemoData else { return }

        do {
            let auth = try await resolvedAuth(authStore: authStore, profile: profile)
            guard let wikiTitle = item.primaryPage?.title else { return }
            if profile.favoriteWikiTitles.contains(wikiTitle) {
                try await socialService.addFavorite(item, auth: auth)
            } else {
                try await socialService.removeFavorite(wikiTitle: wikiTitle, auth: auth)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setFamousTwin(_ item: OnThisDayItem, month: Int, day: Int, profile: ProfileStore, authStore: AuthStore) async {
        profile.setFamousTwin(from: item)
        do {
            try await syncOwnProfile(month: month, day: day, profile: profile, authStore: authStore)
            if !socialService.usesDemoData {
                let auth = try await resolvedAuth(authStore: authStore, profile: profile)
                try await socialService.logActivity(
                    type: "famous_twin",
                    title: "Set \(item.displayName) as your famous twin",
                    detail: nil,
                    auth: auth
                )
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func resolvedAuth(authStore: AuthStore, profile: ProfileStore) async throws -> AuthContext {
        if profile.requiresSignIn {
            let session = try await authStore.validSession()
            return AuthContext(session: session)
        }
        if let session = authStore.session {
            return AuthContext(session: session)
        }
        return AuthContext(
            session: AuthSession(
                userID: profile.clientID,
                accessToken: "",
                refreshToken: "",
                expiresAt: .distantFuture
            )
        )
    }
}
