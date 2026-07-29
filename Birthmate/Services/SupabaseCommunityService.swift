import Foundation

struct SupabaseCommunityService: CommunityService {
    var usesDemoData: Bool { false }
    private let client = SupabaseClient()

    private struct ProfilePayload: Encodable {
        let userID: String
        let displayName: String
        let birthMonth: Int
        let birthDay: Int
        let isDiscoverable: Bool
        let famousTwinName: String?
        let famousTwinWikiTitle: String?

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case displayName = "display_name"
            case birthMonth = "birth_month"
            case birthDay = "birth_day"
            case isDiscoverable = "is_discoverable"
            case famousTwinName = "famous_twin_name"
            case famousTwinWikiTitle = "famous_twin_wiki_title"
        }
    }

    func syncProfile(
        displayName: String,
        month: Int,
        day: Int,
        isDiscoverable: Bool,
        famousTwinName: String?,
        famousTwinWikiTitle: String?,
        auth: AuthContext
    ) async throws {
        guard isDiscoverable else {
            try await removeProfile(auth: auth)
            return
        }

        let payload = ProfilePayload(
            userID: auth.userID,
            displayName: displayName,
            birthMonth: month,
            birthDay: day,
            isDiscoverable: true,
            famousTwinName: famousTwinName,
            famousTwinWikiTitle: famousTwinWikiTitle
        )

        _ = try await client.request(
            path: "birthday_circle",
            method: "POST",
            body: payload,
            prefer: "resolution=merge-duplicates,return=minimal",
            accessToken: auth.accessToken
        )
    }

    func removeProfile(auth: AuthContext) async throws {
        let query = "user_id=eq.\(auth.userID.supabaseQueryEncoded)"
        _ = try await client.request(
            path: "birthday_circle",
            query: query,
            method: "DELETE",
            accessToken: auth.accessToken
        )
    }

    func fetchMembers(
        month: Int,
        day: Int,
        excludingUserID: String,
        auth: AuthContext?
    ) async throws -> [CommunityMember] {
        let query = [
            "birth_month=eq.\(month)",
            "birth_day=eq.\(day)",
            "is_discoverable=eq.true",
            "user_id=neq.\(excludingUserID.supabaseQueryEncoded)",
            "select=user_id,display_name,birth_month,birth_day,famous_twin_name",
            "order=display_name.asc"
        ].joined(separator: "&")

        let data = try await client.request(
            path: "birthday_circle",
            query: query,
            method: "GET",
            accessToken: auth?.accessToken
        )
        return try JSONDecoder().decode([CommunityMember].self, from: data)
    }
}
