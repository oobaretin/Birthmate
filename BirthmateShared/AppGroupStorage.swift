import Foundation

enum AppGroup {
    static let identifier = "group.com.birthmate.app"

    static var defaults: UserDefaults? {
        UserDefaults(suiteName: identifier)
    }

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: identifier)
    }
}

struct WidgetSnapshot: Codable {
    let month: Int
    let day: Int
    let totalCount: Int
    let featuredName: String?
    let featuredYear: Int?
    let updatedAt: Date

    var dateLabel: String {
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(.dateTime.month(.wide).day())
    }
}

enum WidgetDataStore {
    private static let snapshotFileName = "widget-snapshot.json"
    private static let monthKey = "birthmate_month"
    private static let dayKey = "birthmate_day"

    static func syncBirthdate(month: Int, day: Int) {
        AppGroup.defaults?.set(month, forKey: monthKey)
        AppGroup.defaults?.set(day, forKey: dayKey)
    }

    static func clearBirthdate() {
        AppGroup.defaults?.removeObject(forKey: monthKey)
        AppGroup.defaults?.removeObject(forKey: dayKey)
        try? containerFileURL.map { try FileManager.default.removeItem(at: $0) }
    }

    static func update(month: Int, day: Int, totalCount: Int, featuredName: String?, featuredYear: Int?) {
        syncBirthdate(month: month, day: day)
        let snapshot = WidgetSnapshot(
            month: month,
            day: day,
            totalCount: totalCount,
            featuredName: featuredName,
            featuredYear: featuredYear,
            updatedAt: Date()
        )
        save(snapshot)
        WidgetCenterBridge.reloadAllTimelines()
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let url = containerFileURL,
              let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    static func loadBirthdate() -> (month: Int, day: Int)? {
        guard let defaults = AppGroup.defaults else { return nil }
        let month = defaults.integer(forKey: monthKey)
        let day = defaults.integer(forKey: dayKey)
        guard month > 0, day > 0 else { return nil }
        return (month, day)
    }

    private static var containerFileURL: URL? {
        AppGroup.containerURL?.appendingPathComponent(snapshotFileName)
    }

    private static func save(_ snapshot: WidgetSnapshot) {
        guard let url = containerFileURL,
              let data = try? JSONEncoder().encode(snapshot) else { return }
        try? data.write(to: url, options: .atomic)
    }
}

#if canImport(WidgetKit)
import WidgetKit

enum WidgetCenterBridge {
    static func reloadAllTimelines() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
#else
enum WidgetCenterBridge {
    static func reloadAllTimelines() {}
}
#endif
