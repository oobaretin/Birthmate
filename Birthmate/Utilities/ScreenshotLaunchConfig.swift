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
}
#endif
