import Foundation

final class BirthdateStore: ObservableObject {
    @Published var month: Int?
    @Published var day: Int?

    private let monthKey = "birthmate_month"
    private let dayKey = "birthmate_day"

    var hasBirthdate: Bool { month != nil && day != nil }

    init() {
        load()
        #if DEBUG
        if let seeded = ScreenshotLaunchConfig.seededBirthdate {
            save(month: seeded.month, day: seeded.day)
        }
        #endif
    }

    func save(month: Int, day: Int) {
        self.month = month
        self.day = day
        UserDefaults.standard.set(month, forKey: monthKey)
        UserDefaults.standard.set(day, forKey: dayKey)
        WidgetDataStore.syncBirthdate(month: month, day: day)
    }

    func clear() {
        month = nil
        day = nil
        UserDefaults.standard.removeObject(forKey: monthKey)
        UserDefaults.standard.removeObject(forKey: dayKey)
        WidgetDataStore.clearBirthdate()
    }

    private func load() {
        let m = UserDefaults.standard.integer(forKey: monthKey)
        let d = UserDefaults.standard.integer(forKey: dayKey)
        if m > 0 && d > 0 {
            month = m
            day = d
            WidgetDataStore.syncBirthdate(month: m, day: d)
        }
    }
}
