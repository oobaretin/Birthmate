import Foundation

enum OnThisDayType: String {
    case births
    case events
    case deaths
    case selected
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case decodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid request URL."
        case .requestFailed: return "Couldn't reach the server. Check your connection."
        case .decodingFailed: return "Something went wrong reading the data."
        }
    }
}

struct FeedCacheEntry: Codable {
    let items: [OnThisDayItem]
    let fetchedAt: Date
    let isComplete: Bool

    init(items: [OnThisDayItem], fetchedAt: Date, isComplete: Bool = true) {
        self.items = items
        self.fetchedAt = fetchedAt
        self.isComplete = isComplete
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        items = try container.decode([OnThisDayItem].self, forKey: .items)
        fetchedAt = try container.decode(Date.self, forKey: .fetchedAt)
        isComplete = try container.decodeIfPresent(Bool.self, forKey: .isComplete) ?? true
    }
}

final class APIService {
    static let shared = APIService()
    private init() {
        cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BirthmateFeedCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    private let baseURL = "https://en.wikipedia.org/api/rest_v1/feed/onthisday"
    private var memoryCache: [String: FeedCacheEntry] = [:]
    private let cacheDirectory: URL

    func cachedEntry(type: OnThisDayType, month: Int, day: Int) -> FeedCacheEntry? {
        let key = cacheKey(type: type, month: month, day: day)
        if let cached = memoryCache[key] { return cached }
        if let disk = loadFromDisk(key: key) {
            memoryCache[key] = disk
            return disk
        }
        return nil
    }

    func fetch(type: OnThisDayType, month: Int, day: Int, forceRefresh: Bool = false) async throws -> FeedCacheEntry {
        let key = cacheKey(type: type, month: month, day: day)
        if !forceRefresh, let cached = cachedEntry(type: type, month: month, day: day) {
            return cached
        }

        let monthStr = String(format: "%02d", month)
        let dayStr = String(format: "%02d", day)
        guard let url = URL(string: "\(baseURL)/\(type.rawValue)/\(monthStr)/\(dayStr)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        do {
            let (responseData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw APIError.requestFailed
            }
            data = responseData
        } catch is APIError {
            throw APIError.requestFailed
        } catch {
            throw APIError.requestFailed
        }

        do {
            let decoded = try JSONDecoder().decode(OnThisDayResponse.self, from: data)
            let items: [OnThisDayItem]
            switch type {
            case .births: items = decoded.births ?? []
            case .events: items = decoded.events ?? []
            case .deaths: items = decoded.deaths ?? []
            case .selected: items = decoded.selected ?? []
            }
            let entry = FeedCacheEntry(items: items, fetchedAt: Date())
            memoryCache[key] = entry
            saveToDisk(entry, key: key)
            return entry
        } catch {
            throw APIError.decodingFailed
        }
    }

    private func cacheKey(type: OnThisDayType, month: Int, day: Int) -> String {
        "\(type.rawValue)-\(month)-\(day)"
    }

    private func diskURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key).appendingPathExtension("json")
    }

    private func loadFromDisk(key: String) -> FeedCacheEntry? {
        let url = diskURL(for: key)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(FeedCacheEntry.self, from: data)
    }

    private func saveToDisk(_ entry: FeedCacheEntry, key: String) {
        let url = diskURL(for: key)
        guard let data = try? JSONEncoder().encode(entry) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
