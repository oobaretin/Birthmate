import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(AppTab.today)

            HomeView()
                .tabItem { Label("People", systemImage: "person.2.fill") }
                .tag(AppTab.people)

            OnThisDayView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(BirthmateTheme.accent)
    }
}
