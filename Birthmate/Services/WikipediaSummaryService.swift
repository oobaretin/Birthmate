import Foundation

final class WikipediaSummaryService {
    static let shared = WikipediaSummaryService()

    func fetchExtract(for item: OnThisDayItem) async -> String? {
        guard item.primaryPage?.extract == nil,
              let title = wikipediaTitle(for: item) else {
            return item.primaryPage?.extract
        }
        guard let summary = await fetchSummary(title: title) else { return nil }
        return summary.extract
    }

    func fetchThumbnailURL(for item: OnThisDayItem) async -> String? {
        guard let title = wikipediaTitle(for: item),
              let summary = await fetchSummary(title: title) else {
            return nil
        }
        return WikiImageURL.resolved(summary.thumbnail?.source)
    }

    func fetchThumbnailURL(title: String) async -> String? {
        guard let summary = await fetchSummary(title: title) else { return nil }
        return WikiImageURL.resolved(summary.thumbnail?.source)
    }

    private func wikipediaTitle(for item: OnThisDayItem) -> String? {
        if let title = item.primaryPage?.title, !title.isEmpty { return title }
        guard let urlString = item.primaryPage?.contentUrls?.desktop?.page,
              let url = URL(string: urlString) else { return nil }
        return url.lastPathComponent
    }

    private func fetchSummary(title: String) async -> WikipediaSummary? {
        guard let encoded = WikipediaTitleEncoding.apiPath(for: title),
              let summaryURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            return nil
        }

        var request = URLRequest(url: summaryURL)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Birthmate/1.0 (iOS app)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            return try JSONDecoder().decode(WikipediaSummary.self, from: data)
        } catch {
            return nil
        }
    }
}

enum WikipediaTitleEncoding {
    static func apiPath(for title: String) -> String? {
        let decoded = title.removingPercentEncoding ?? title
        let normalized = decoded.replacingOccurrences(of: " ", with: "_")
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        return normalized.addingPercentEncoding(withAllowedCharacters: allowed)
    }
}

private struct WikipediaSummary: Decodable {
    let extract: String?
    let thumbnail: WikipediaThumbnail?
}

private struct WikipediaThumbnail: Decodable {
    let source: String
}
