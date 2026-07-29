import Foundation

// MARK: - Top-level response for a given type (births, events, deaths, selected)
struct OnThisDayResponse: Codable {
    let births: [OnThisDayItem]?
    let events: [OnThisDayItem]?
    let deaths: [OnThisDayItem]?
    let selected: [OnThisDayItem]?
}

// MARK: - A single event/birth/death entry
struct OnThisDayItem: Codable, Identifiable, Hashable {
    let text: String
    let year: Int?
    let pages: [WikiPage]?

    var id: String { "\(year ?? 0)-\(WikiFormatting.personName(from: self))" }

    var primaryPage: WikiPage? { pages?.first }
}

// MARK: - A linked Wikipedia page (person, event topic, etc.)
struct WikiPage: Codable, Hashable {
    let title: String
    let displayTitle: String?
    let extract: String?
    let thumbnail: WikiImage?
    let originalImage: WikiImage?
    let contentUrls: ContentUrls?

    enum CodingKeys: String, CodingKey {
        case title
        case displayTitle = "displaytitle"
        case extract
        case thumbnail
        case originalImage = "originalimage"
        case contentUrls = "content_urls"
    }
}

struct WikiImage: Codable, Hashable {
    let source: String
    let width: Int?
    let height: Int?
}

struct ContentUrls: Codable, Hashable {
    let desktop: ContentUrlDetail?
    let mobile: ContentUrlDetail?
}

struct ContentUrlDetail: Codable, Hashable {
    let page: String
}
