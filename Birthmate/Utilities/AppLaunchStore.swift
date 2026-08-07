import Foundation

enum AppLaunchStore {
    static let launchCountKey = "birthmate_launch_count"

    static var launchCount: Int {
        UserDefaults.standard.integer(forKey: launchCountKey)
    }

    static func recordLaunchIfNeeded() {
        let key = "birthmate_launch_recorded_\(Self.sessionDayKey())"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(launchCount + 1, forKey: launchCountKey)
        UserDefaults.standard.set(true, forKey: key)
    }

    private static func sessionDayKey() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
