import Foundation

enum WikiFormatting {
    static func plainText(from html: String) -> String {
        let withoutTags = html.replacingOccurrences(
            of: "<[^>]+>",
            with: "",
            options: .regularExpression
        )
        return decodeHTMLEntities(withoutTags)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func personName(from item: OnThisDayItem) -> String {
        let raw: String
        if let displayTitle = item.primaryPage?.displayTitle {
            let plain = plainText(from: displayTitle)
            if !plain.isEmpty {
                raw = plain
            } else if let title = item.primaryPage?.title {
                raw = decodeWikiTitle(title)
            } else {
                raw = item.text.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? item.text
            }
        } else if let title = item.primaryPage?.title {
            raw = decodeWikiTitle(title)
        } else {
            raw = item.text.components(separatedBy: ",").first?.trimmingCharacters(in: .whitespaces) ?? item.text
        }

        return cleanPersonName(raw)
    }

    private static func decodeWikiTitle(_ title: String) -> String {
        decodeHTMLEntities(title.removingPercentEncoding ?? title)
            .replacingOccurrences(of: "_", with: " ")
    }

    private static func cleanPersonName(_ name: String) -> String {
        var cleaned = name.trimmingCharacters(in: .whitespacesAndNewlines)

        cleaned = cleaned.replacingOccurrences(
            of: #"\s*\((?:[^)]*\bborn\s+\d{4}[^)]*)\)"#,
            with: "",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #"\s*\((?:died|d\.|b\.)\s+\d{4}[^)]*\)"#,
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeHTMLEntities(_ text: String) -> String {
        var result = text

        if let decimalRegex = try? NSRegularExpression(pattern: "&#(\\d+);") {
            result = replaceEntityMatches(in: result, regex: decimalRegex) { code in
                Unicode.Scalar(code).map { String(Character($0)) }
            }
        }

        if let hexRegex = try? NSRegularExpression(pattern: "&#x([0-9A-Fa-f]+);") {
            result = replaceEntityMatches(in: result, regex: hexRegex) { code in
                Unicode.Scalar(code).map { String(Character($0)) }
            }
        }

        return result
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&#039;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
    }

    private static func replaceEntityMatches(
        in text: String,
        regex: NSRegularExpression,
        transform: (UInt32) -> String?
    ) -> String {
        var result = text
        let nsRange = NSRange(result.startIndex..<result.endIndex, in: result)

        for match in regex.matches(in: result, options: [], range: nsRange).reversed() {
            guard match.numberOfRanges >= 2,
                  let codeRange = Range(match.range(at: 1), in: result),
                  let fullRange = Range(match.range, in: result),
                  let code = UInt32(result[codeRange]),
                  let replacement = transform(code) else { continue }
            result.replaceSubrange(fullRange, with: replacement)
        }

        return result
    }

    static func eventText(from item: OnThisDayItem) -> String {
        plainText(from: item.text)
    }

    static func isValidPersonLabel(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        if trimmed == "Unknown value" { return false }
        if trimmed.range(of: #"^Q\d+$"#, options: .regularExpression) != nil { return false }
        if trimmed.lowercased().contains("wikidata.org") { return false }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") { return false }
        return true
    }

    static func isLiving(_ item: OnThisDayItem) -> Bool {
        !item.text.lowercased().contains("(died")
    }

    static func eventYear(for item: OnThisDayItem) -> Int? {
        if let year = item.year { return year }
        if let match = item.text.range(of: #"^\d{4}"#, options: .regularExpression) {
            return Int(item.text[match])
        }
        return nil
    }

    static func birthYear(for item: OnThisDayItem) -> Int? { eventYear(for: item) }

    static func shareText(for item: OnThisDayItem, dateLabel: String, isBirth: Bool = false) -> String {
        if isBirth {
            return "I share a birthday (\(dateLabel)) with \(item.displayName)! Discover yours with Birthmate."
        }
        return "On \(dateLabel): \(eventText(from: item)) — via Birthmate"
    }
}

extension OnThisDayItem {
    var displayName: String { WikiFormatting.personName(from: self) }
    var displayText: String { WikiFormatting.eventText(from: self) }
    var eventYear: Int? { WikiFormatting.eventYear(for: self) }
    var birthYear: Int? { WikiFormatting.eventYear(for: self) }
    var isLiving: Bool { WikiFormatting.isLiving(self) }
    var hasValidBirthYear: Bool {
        guard let year = birthYear else { return false }
        return year <= Calendar.current.component(.year, from: Date())
    }
    var hasValidEventYear: Bool {
        guard let year = eventYear else { return false }
        return year <= Calendar.current.component(.year, from: Date())
    }
}

struct FeedSection: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let items: [OnThisDayItem]
}

typealias BirthSection = FeedSection

enum HistoryEra: CaseIterable {
    case recent
    case twentiethCentury
    case nineteenthCentury
    case earlier

    var title: String {
        switch self {
        case .recent: return "2000 & Later"
        case .twentiethCentury: return "1900 – 1999"
        case .nineteenthCentury: return "1800 – 1899"
        case .earlier: return "Before 1800"
        }
    }

    func contains(year: Int) -> Bool {
        switch self {
        case .recent: return year >= 2000
        case .twentiethCentury: return year >= 1900 && year < 2000
        case .nineteenthCentury: return year >= 1800 && year < 1900
        case .earlier: return year < 1800
        }
    }

    var sortOrder: Int {
        switch self {
        case .recent: return 0
        case .twentiethCentury: return 1
        case .nineteenthCentury: return 2
        case .earlier: return 3
        }
    }
}

enum BirthFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case living = "Living"
    case historical = "Historical"
    case favorites = "Favorites"
    var id: String { rawValue }
}

enum EventFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case highlights = "Highlights"
    case events = "Events"
    var id: String { rawValue }
}

enum FeedSectionBuilder {
    static func build(from items: [OnThisDayItem], yearKeyPath: (OnThisDayItem) -> Int?) -> [FeedSection] {
        HistoryEra.allCases.compactMap { era in
            let eraItems = items.filter { item in
                guard let year = yearKeyPath(item) else { return false }
                return era.contains(year: year)
            }
            guard !eraItems.isEmpty else { return nil }
            return FeedSection(
                id: era.title,
                title: era.title,
                subtitle: "\(eraItems.count) entries",
                items: eraItems
            )
        }
        .sorted { lhs, rhs in
            let left = HistoryEra.allCases.first { $0.title == lhs.title }?.sortOrder ?? 99
            let right = HistoryEra.allCases.first { $0.title == rhs.title }?.sortOrder ?? 99
            return left < right
        }
    }
}
