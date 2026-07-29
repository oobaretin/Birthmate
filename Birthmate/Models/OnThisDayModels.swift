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

enum OnThisDayMerger {
    /// Combines multiple On This Day lists, deduplicating by Wikipedia title or name+year.
    /// Keeps the entry with richer page data (thumbnail, extract, etc.).
    static func merge(_ lists: [OnThisDayItem]...) -> [OnThisDayItem] {
        merge(lists.flatMap { $0 })
    }

    static func merge(_ lists: [[OnThisDayItem]]) -> [OnThisDayItem] {
        var byKey: [String: OnThisDayItem] = [:]
        for list in lists {
            for item in list {
                let key = mergeKey(for: item)
                if let existing = byKey[key] {
                    byKey[key] = preferRicher(existing, item)
                } else {
                    byKey[key] = item
                }
            }
        }
        return Array(byKey.values)
    }

    static func mergeKey(for item: OnThisDayItem) -> String {
        if let title = item.primaryPage?.title {
            return normalizeWikiTitle(title)
        }
        let year = item.birthYear ?? item.eventYear ?? 0
        return "\(year)-\(item.displayName.lowercased())"
    }

    private static func normalizeWikiTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "_", with: " ")
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func preferRicher(_ lhs: OnThisDayItem, _ rhs: OnThisDayItem) -> OnThisDayItem {
        richnessScore(rhs) > richnessScore(lhs) ? rhs : lhs
    }

    private static func richnessScore(_ item: OnThisDayItem) -> Int {
        var score = 0
        if item.primaryPage?.thumbnail?.source != nil { score += 4 }
        if item.primaryPage?.originalImage?.source != nil { score += 2 }
        if let extract = item.primaryPage?.extract, !extract.isEmpty { score += 3 }
        if item.year != nil { score += 1 }
        if item.primaryPage?.contentUrls?.desktop?.page != nil { score += 1 }
        return score
    }
}
