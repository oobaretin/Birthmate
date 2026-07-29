import Foundation

protocol CommunityService: Sendable {
    var usesDemoData: Bool { get }
    func syncProfile(
        displayName: String,
        month: Int,
        day: Int,
        isDiscoverable: Bool,
        famousTwinName: String?,
        famousTwinWikiTitle: String?,
        auth: AuthContext
    ) async throws
    func removeProfile(auth: AuthContext) async throws
    func fetchMembers(month: Int, day: Int, excludingUserID: String, auth: AuthContext?) async throws -> [CommunityMember]
}

protocol SocialService: Sendable {
    var usesDemoData: Bool { get }
    func fetchFavorites(auth: AuthContext) async throws -> [FavoriteBirthmate]
    func addFavorite(_ item: OnThisDayItem, auth: AuthContext) async throws
    func removeFavorite(wikiTitle: String, auth: AuthContext) async throws
    func fetchFriendships(auth: AuthContext) async throws -> [Friendship]
    func sendFriendRequest(to userID: String, auth: AuthContext) async throws
    func respondToFriendRequest(id: String, accept: Bool, auth: AuthContext) async throws
    func fetchActivity(auth: AuthContext) async throws -> [ActivityEvent]
    func logActivity(type: String, title: String, detail: String?, auth: AuthContext) async throws
}

enum CommunityServiceProvider {
    static let shared: CommunityService = {
        if BirthmateSecrets.appleSignInEnabled, BirthmateSecrets.isCommunityConfigured {
            return SupabaseCommunityService()
        }
        return MockCommunityService()
    }()
}

enum SocialServiceProvider {
    static let shared: SocialService = {
        if BirthmateSecrets.appleSignInEnabled, BirthmateSecrets.isCommunityConfigured {
            return SupabaseSocialService()
        }
        return MockSocialService()
    }()
}

enum CommunityError: Error, LocalizedError {
    case notConfigured
    case invalidResponse
    case serverError(String)
    case signInRequired

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Community is not configured yet."
        case .invalidResponse:
            return "Unexpected response from the community service."
        case .serverError(let message):
            return message
        case .signInRequired:
            return "Sign in with Apple to use Birthday Circle."
        }
    }
}
