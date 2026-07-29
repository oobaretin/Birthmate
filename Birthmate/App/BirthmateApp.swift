import SwiftUI

@main
struct BirthmateApp: App {
    @StateObject private var birthdateStore = BirthdateStore()
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var profileStore = ProfileStore()
    @StateObject private var authStore = AuthStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(birthdateStore)
                .environmentObject(notificationManager)
                .environmentObject(profileStore)
                .environmentObject(authStore)
                .onOpenURL { url in
                    authStore.handleInviteURL(url)
                }
        }
    }
}
