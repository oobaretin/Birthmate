import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Your Day", systemImage: "person.2.fill") }

            OnThisDayView()
                .tabItem { Label("On This Day", systemImage: "clock.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(BirthmateTheme.accent)
    }
}
