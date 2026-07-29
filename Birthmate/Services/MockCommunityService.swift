import Foundation

struct MockCommunityService: CommunityService {
    var usesDemoData: Bool { true }

    func syncProfile(
        displayName: String,
        month: Int,
        day: Int,
        isDiscoverable: Bool,
        famousTwinName: String?,
        famousTwinWikiTitle: String?,
        auth: AuthContext
    ) async throws {
        try await Task.sleep(nanoseconds: 200_000_000)
    }

    func removeProfile(auth: AuthContext) async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
    }

    func fetchMembers(
        month: Int,
        day: Int,
        excludingUserID: String,
        auth: AuthContext?
    ) async throws -> [CommunityMember] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            CommunityMember(id: "demo-1", displayName: "Alex", birthMonth: month, birthDay: day, famousTwinName: "Sample Star"),
            CommunityMember(id: "demo-2", displayName: "Jordan", birthMonth: month, birthDay: day),
            CommunityMember(id: "demo-3", displayName: "Sam", birthMonth: month, birthDay: day),
            CommunityMember(id: "demo-4", displayName: "Riley", birthMonth: month, birthDay: day)
        ]
    }
}

struct MockSocialService: SocialService {
    var usesDemoData: Bool { true }

    func fetchFavorites(auth: AuthContext) async throws -> [FavoriteBirthmate] { [] }
    func addFavorite(_ item: OnThisDayItem, auth: AuthContext) async throws {}
    func removeFavorite(wikiTitle: String, auth: AuthContext) async throws {}
    func fetchFriendships(auth: AuthContext) async throws -> [Friendship] { [] }
    func sendFriendRequest(to userID: String, auth: AuthContext) async throws {}
    func respondToFriendRequest(id: String, accept: Bool, auth: AuthContext) async throws {}
    func fetchActivity(auth: AuthContext) async throws -> [ActivityEvent] {
        [
            ActivityEvent(
                id: "1",
                eventType: "welcome",
                title: "Preview: Birthday Circle",
                detail: "Sample activity shown until live sign-in is available.",
                createdAt: Date()
            )
        ]
    }
    func logActivity(type: String, title: String, detail: String?, auth: AuthContext) async throws {}
}
