import Foundation
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: enabledKey)
        }
    }

    @Published var reminderTime: Date {
        didSet {
            persistReminderTime()
        }
    }

    private let enabledKey = "birthmate_notifications_enabled"
    private let hourKey = "birthmate_reminder_hour"
    private let minuteKey = "birthmate_reminder_minute"
    private let notificationID = "birthmate_daily_reminder"

    var reminderTimeLabel: String {
        reminderTime.formatted(date: .omitted, time: .shortened)
    }

    init() {
        isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        reminderTime = Self.loadReminderTime()
    }

    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(month: Int, day: Int) async {
        guard isEnabled else { return }

        let granted = await requestPermission()
        guard granted else {
            isEnabled = false
            return
        }

        cancelReminders()

        let time = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        var dateComponents = DateComponents()
        dateComponents.hour = time.hour ?? 9
        dateComponents.minute = time.minute ?? 0

        let content = UNMutableNotificationContent()
        content.title = "Birthmate"
        content.body = "See who shares your birthday today."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }

    func handleToggleChange(enabled: Bool, month: Int?, day: Int?) async {
        if enabled {
            guard let month, let day else {
                isEnabled = false
                return
            }
            await scheduleDailyReminder(month: month, day: day)
        } else {
            cancelReminders()
        }
    }

    private func persistReminderTime() {
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        UserDefaults.standard.set(components.hour ?? 9, forKey: hourKey)
        UserDefaults.standard.set(components.minute ?? 0, forKey: minuteKey)
    }

    private static func loadReminderTime() -> Date {
        let hour = UserDefaults.standard.object(forKey: "birthmate_reminder_hour") as? Int ?? 9
        let minute = UserDefaults.standard.object(forKey: "birthmate_reminder_minute") as? Int ?? 0
        var components = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
