import Foundation

enum WikiImageURL {
    /// Normalizes Wikidata Commons URLs to HTTPS direct thumbnail links AsyncImage can load.
    static func resolved(_ raw: String?, width: Int = 330) -> String? {
        guard var url = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else {
            return nil
        }
        if url.hasPrefix("http://") {
            url = "https://" + url.dropFirst(7)
        }
        if url.contains("commons.wikimedia.org/wiki/Special:FilePath/"), !url.contains("width=") {
            url += (url.contains("?") ? "&" : "?") + "width=\(width)"
        }
        return url
    }

    static func url(from resolved: String) -> URL? {
        if let url = URL(string: resolved) { return url }
        return URL(string: resolved, encodingInvalidCharacters: true)
    }
}

struct WikidataSPARQLResponse: Decodable {
    let results: WikidataResults
}

struct WikidataResults: Decodable {
    let bindings: [WikidataBinding]
}

struct WikidataBinding: Decodable {
    let person: WikidataValue?
    let personLabel: WikidataValue?
    let birth: WikidataValue?
    let death: WikidataValue?
    let image: WikidataValue?
    let article: WikidataValue?
}

struct WikidataValue: Decodable {
    let value: String
}

enum WikidataError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid Wikidata request."
        case .requestFailed: return "Couldn't reach Wikidata. Check your connection."
        case .decodingFailed: return "Couldn't read Wikidata response."
        }
    }
}

extension OnThisDayItem {
    static func fromWikidata(binding: WikidataBinding) -> OnThisDayItem? {
        guard let name = binding.personLabel?.value,
              !name.hasPrefix("Q"),
              name != "Unknown value" else { return nil }

        let birthISO = binding.birth?.value ?? ""
        let year = Self.parseYear(from: birthISO)
        let deathYear = binding.death.map { Self.parseYear(from: $0.value) }

        var text = name
        if let deathYear {
            text += " (died \(deathYear))"
        }

        let imageURL = WikiImageURL.resolved(binding.image?.value)
        let thumb = imageURL.map { WikiImage(source: $0, width: nil, height: nil) }
        let wikiPageURL = binding.article?.value
        let wikiTitle = wikiPageURL?
            .replacingOccurrences(of: "https://en.wikipedia.org/wiki/", with: "")

        let page = WikiPage(
            title: wikiTitle ?? name.replacingOccurrences(of: " ", with: "_"),
            displayTitle: name,
            extract: nil,
            thumbnail: thumb,
            originalImage: thumb,
            contentUrls: wikiPageURL.map {
                ContentUrls(desktop: ContentUrlDetail(page: $0), mobile: nil)
            }
        )

        return OnThisDayItem(text: text, year: year, pages: [page])
    }

    private static func parseYear(from isoDate: String) -> Int? {
        if isoDate.count >= 4, let year = Int(isoDate.prefix(4)) { return year }
        return nil
    }
}
