import Foundation

final class WikidataService {
    static let shared = WikidataService()

    private let endpoint = URL(string: "https://query.wikidata.org/sparql")!
    private let userAgent = "Birthmate/1.0 (iOS app; birthmate)"
    private var memoryCache: [String: FeedCacheEntry] = [:]
    private let cacheDirectory: URL

    private let minBirthYear = 1800
    private let maxConcurrentYearFetches = 12

    private init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BirthmateWikidataCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    func cachedBirths(month: Int, day: Int) -> FeedCacheEntry? {
        let key = cacheKey(month: month, day: day)
        if let cached = memoryCache[key] { return cached }
        if let disk = loadFromDisk(key: key) {
            memoryCache[key] = disk
            return disk
        }
        return nil
    }

    func fetchBirths(
        month: Int,
        day: Int,
        forceRefresh: Bool = false,
        onPartialUpdate: (@Sendable ([OnThisDayItem]) -> Void)? = nil
    ) async throws -> FeedCacheEntry {
        let key = cacheKey(month: month, day: day)
        if !forceRefresh,
           let cached = cachedBirths(month: month, day: day),
           cached.isComplete {
            return cached
        }

        let currentYear = Calendar.current.component(.year, from: Date())
        // Recent years first so familiar names appear within seconds.
        let years = Array((minBirthYear...currentYear).reversed())
        var collected: [String: OnThisDayItem] = [:]

        if let partial = cachedBirths(month: month, day: day), forceRefresh {
            for item in partial.items {
                collected[item.id] = item
            }
        }

        try await withThrowingTaskGroup(of: [OnThisDayItem].self) { group in
            var yearIndex = 0

            func addNextYearTask() {
                guard yearIndex < years.count else { return }
                let year = years[yearIndex]
                yearIndex += 1
                group.addTask {
                    try await self.fetchBirthsForYear(year, month: month, day: day)
                }
            }

            for _ in 0..<min(maxConcurrentYearFetches, years.count) {
                addNextYearTask()
            }

            while let batch = try await group.next() {
                for item in batch {
                    collected[item.id] = item
                }
                let snapshot = sortedItems(from: collected)
                persistPartial(snapshot, key: key)
                onPartialUpdate?(snapshot)

                if yearIndex < years.count {
                    addNextYearTask()
                }
            }
        }

        let items = sortedItems(from: collected)
        let entry = FeedCacheEntry(items: items, fetchedAt: Date(), isComplete: true)
        memoryCache[key] = entry
        saveToDisk(entry, key: key)
        return entry
    }

    private func sortedItems(from collected: [String: OnThisDayItem]) -> [OnThisDayItem] {
        collected.values
            .filter(\.hasValidBirthYear)
            .sorted { ($0.birthYear ?? 0) > ($1.birthYear ?? 0) }
    }

    private func persistPartial(_ items: [OnThisDayItem], key: String) {
        guard !items.isEmpty else { return }
        let entry = FeedCacheEntry(items: items, fetchedAt: Date(), isComplete: false)
        memoryCache[key] = entry
        saveToDisk(entry, key: key)
    }

    private func fetchBirthsForYear(_ year: Int, month: Int, day: Int) async throws -> [OnThisDayItem] {
        var startComponents = DateComponents(year: year, month: month, day: day)
        let calendar = Calendar(identifier: .gregorian)
        guard let startDate = calendar.date(from: startComponents),
              let endDate = calendar.date(byAdding: .day, value: 1, to: startDate) else {
            return []
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let startISO = formatter.string(from: startDate)
        let endISO = formatter.string(from: endDate)

        let query = """
        SELECT ?person ?personLabel ?birth ?death ?image ?article WHERE {
          ?person wdt:P31 wd:Q5;
                  wdt:P569 ?birth;
                  ^schema:about ?article.
          ?article schema:isPartOf <https://en.wikipedia.org/>.
          FILTER(?birth >= "\(startISO)"^^xsd:dateTime && ?birth < "\(endISO)"^^xsd:dateTime)
          OPTIONAL { ?person wdt:P570 ?death. }
          OPTIONAL { ?person wdt:P18 ?image. }
          SERVICE wikibase:label { bd:serviceParam wikibase:language "en". }
        }
        """

        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "query", value: query)]

        guard let url = components.url else { throw WikidataError.invalidURL }

        var request = URLRequest(url: url)
        request.setValue("application/sparql-results+json", forHTTPHeaderField: "Accept")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 20

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw WikidataError.requestFailed
        }

        let decoded = try JSONDecoder().decode(WikidataSPARQLResponse.self, from: data)
        return decoded.results.bindings.compactMap(OnThisDayItem.fromWikidata)
    }

    private func cacheKey(month: Int, day: Int) -> String {
        "wikidata-births-\(month)-\(day)"
    }

    private func diskURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
    }

    private func loadFromDisk(key: String) -> FeedCacheEntry? {
        guard let data = try? Data(contentsOf: diskURL(for: key)) else { return nil }
        return try? JSONDecoder().decode(FeedCacheEntry.self, from: data)
    }

    private func saveToDisk(_ entry: FeedCacheEntry, key: String) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: diskURL(for: key), options: .atomic)
    }
}
