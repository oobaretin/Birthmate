#if DEBUG
import Foundation

/// Launch-argument helpers for App Store screenshot automation (Simulator only).
enum ScreenshotLaunchConfig {
    static var selectedTab: AppTab? {
        guard let arg = CommandLine.arguments.first(where: { $0.hasPrefix("-ScreenshotTab=") }) else {
            return nil
        }
        let value = String(arg.dropFirst("-ScreenshotTab=".count)).lowercased()
        switch value {
        case "today":
            return .today
        case "birthmates", "people":
            return .people
        case "history":
            return .history
        case "settings":
            return .settings
        default:
            return nil
        }
    }

    static var skipNotificationPrompt: Bool {
        CommandLine.arguments.contains("-SkipNotificationPrompt")
    }

    static var seededBirthdate: (month: Int, day: Int)? {
        guard let arg = CommandLine.arguments.first(where: { $0.hasPrefix("-ScreenshotBirthdate=") }) else {
            return nil
        }
        let value = String(arg.dropFirst("-ScreenshotBirthdate=".count))
        let parts = value.split(separator: "/")
        guard parts.count == 2,
              let month = Int(parts[0]), (1 ... 12).contains(month),
              let day = Int(parts[1]), (1 ... 31).contains(day) else {
            return nil
        }
        return (month, day)
    }
}
#endif
