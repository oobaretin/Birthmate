import SwiftUI

@main
struct BirthmateApp: App {
    @StateObject private var birthdateStore = BirthdateStore()
    @StateObject private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(birthdateStore)
                .environmentObject(notificationManager)
        }
    }
}
