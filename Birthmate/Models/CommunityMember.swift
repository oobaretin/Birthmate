import Foundation

struct CommunityMember: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let displayName: String
    let birthMonth: Int
    let birthDay: Int
    let famousTwinName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userID = "user_id"
        case clientID = "client_id"
        case displayName = "display_name"
        case birthMonth = "birth_month"
        case birthDay = "birth_day"
        case famousTwinName = "famous_twin_name"
    }

    init(
        id: String,
        displayName: String,
        birthMonth: Int,
        birthDay: Int,
        famousTwinName: String? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.birthMonth = birthMonth
        self.birthDay = birthDay
        self.famousTwinName = famousTwinName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let userID = try container.decodeIfPresent(String.self, forKey: .userID) {
            id = userID
        } else if let clientID = try container.decodeIfPresent(String.self, forKey: .clientID) {
            id = clientID
        } else {
            id = try container.decode(String.self, forKey: .id)
        }
        displayName = try container.decode(String.self, forKey: .displayName)
        birthMonth = try container.decode(Int.self, forKey: .birthMonth)
        birthDay = try container.decode(Int.self, forKey: .birthDay)
        famousTwinName = try container.decodeIfPresent(String.self, forKey: .famousTwinName)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .userID)
        try container.encode(displayName, forKey: .displayName)
        try container.encode(birthMonth, forKey: .birthMonth)
        try container.encode(birthDay, forKey: .birthDay)
        try container.encodeIfPresent(famousTwinName, forKey: .famousTwinName)
    }

    var initials: String {
        let parts = displayName.split(separator: " ").prefix(2)
        let letters = parts.compactMap(\.first).map(String.init)
        return letters.isEmpty ? "?" : letters.joined().uppercased()
    }
}

struct FavoriteBirthmate: Identifiable, Codable, Hashable, Sendable {
    var id: String { wikiTitle }
    let wikiTitle: String
    let displayName: String

    enum CodingKeys: String, CodingKey {
        case wikiTitle = "wiki_title"
        case displayName = "display_name"
    }
}

struct Friendship: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let requesterID: String
    let addresseeID: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case id
        case requesterID = "requester_id"
        case addresseeID = "addressee_id"
        case status
    }

    var isPending: Bool { status == "pending" }
    var isAccepted: Bool { status == "accepted" }
}

struct ActivityEvent: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let eventType: String
    let title: String
    let detail: String?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case eventType = "event_type"
        case title
        case detail
        case createdAt = "created_at"
    }
}
