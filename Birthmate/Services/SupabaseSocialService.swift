import Foundation

struct SupabaseSocialService: SocialService {
    var usesDemoData: Bool { false }
    private let client = SupabaseClient()
    private static let isoDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let value = try container.decode(String.self)
            let fractional = ISO8601DateFormatter()
            fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fractional.date(from: value) { return date }
            let standard = ISO8601DateFormatter()
            standard.formatOptions = [.withInternetDateTime]
            if let date = standard.date(from: value) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date: \(value)")
        }
        return decoder
    }()

    func fetchFavorites(auth: AuthContext) async throws -> [FavoriteBirthmate] {
        let query = "user_id=eq.\(auth.userID.supabaseQueryEncoded)&select=wiki_title,display_name&order=created_at.desc"
        let data = try await client.request(path: "favorite_birthmates", query: query, method: "GET", accessToken: auth.accessToken)
        return try JSONDecoder().decode([FavoriteBirthmate].self, from: data)
    }

    func addFavorite(_ item: OnThisDayItem, auth: AuthContext) async throws {
        struct Payload: Encodable {
            let userID: String
            let wikiTitle: String
            let displayName: String

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case wikiTitle = "wiki_title"
                case displayName = "display_name"
            }
        }

        guard let wikiTitle = item.primaryPage?.title else { return }
        let payload = Payload(userID: auth.userID, wikiTitle: wikiTitle, displayName: item.displayName)
        _ = try await client.request(
            path: "favorite_birthmates",
            method: "POST",
            body: payload,
            prefer: "resolution=merge-duplicates,return=minimal",
            accessToken: auth.accessToken
        )
        try await logActivity(
            type: "favorite",
            title: "Favorited \(item.displayName)",
            detail: nil,
            auth: auth
        )
    }

    func removeFavorite(wikiTitle: String, auth: AuthContext) async throws {
        let query = "user_id=eq.\(auth.userID.supabaseQueryEncoded)&wiki_title=eq.\(wikiTitle.supabaseQueryEncoded)"
        _ = try await client.request(path: "favorite_birthmates", query: query, method: "DELETE", accessToken: auth.accessToken)
    }

    func fetchFriendships(auth: AuthContext) async throws -> [Friendship] {
        let query = "or=(requester_id.eq.\(auth.userID.supabaseQueryEncoded),addressee_id.eq.\(auth.userID.supabaseQueryEncoded))&select=id,requester_id,addressee_id,status&order=created_at.desc"
        let data = try await client.request(path: "friendships", query: query, method: "GET", accessToken: auth.accessToken)
        return try JSONDecoder().decode([Friendship].self, from: data)
    }

    func sendFriendRequest(to userID: String, auth: AuthContext) async throws {
        struct Payload: Encodable {
            let requesterID: String
            let addresseeID: String
            let status: String

            enum CodingKeys: String, CodingKey {
                case requesterID = "requester_id"
                case addresseeID = "addressee_id"
                case status
            }
        }

        let payload = Payload(requesterID: auth.userID, addresseeID: userID, status: "pending")
        _ = try await client.request(path: "friendships", method: "POST", body: payload, accessToken: auth.accessToken)
        try await logActivity(type: "friend_request_sent", title: "Friend request sent", detail: nil, auth: auth)
    }

    func respondToFriendRequest(id: String, accept: Bool, auth: AuthContext) async throws {
        struct Payload: Encodable { let status: String }
        let query = "id=eq.\(id.supabaseQueryEncoded)"
        _ = try await client.request(
            path: "friendships",
            query: query,
            method: "PATCH",
            body: Payload(status: accept ? "accepted" : "declined"),
            accessToken: auth.accessToken
        )
        if accept {
            try await logActivity(type: "friend_accepted", title: "Friend request accepted", detail: nil, auth: auth)
        }
    }

    func fetchActivity(auth: AuthContext) async throws -> [ActivityEvent] {
        let query = "user_id=eq.\(auth.userID.supabaseQueryEncoded)&select=id,event_type,title,detail,created_at&order=created_at.desc&limit=20"
        let data = try await client.request(path: "activity_events", query: query, method: "GET", accessToken: auth.accessToken)
        return try Self.isoDecoder.decode([ActivityEvent].self, from: data)
    }

    func logActivity(type: String, title: String, detail: String?, auth: AuthContext) async throws {
        struct Payload: Encodable {
            let userID: String
            let eventType: String
            let title: String
            let detail: String?

            enum CodingKeys: String, CodingKey {
                case userID = "user_id"
                case eventType = "event_type"
                case title
                case detail
            }
        }

        let payload = Payload(userID: auth.userID, eventType: type, title: title, detail: detail)
        _ = try await client.request(path: "activity_events", method: "POST", body: payload, accessToken: auth.accessToken)
    }
}
