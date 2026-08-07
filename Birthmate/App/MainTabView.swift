import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(AppTab.today)

            HomeView()
                .tabItem { Label("Birthmates", systemImage: "person.2.fill") }
                .tag(AppTab.people)

            OnThisDayView()
                .tabItem { Label("On This Day", systemImage: "clock.fill") }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(BirthmateTheme.accent)
        .onAppear {
            AppLaunchStore.recordLaunchIfNeeded()
            #if DEBUG
            if let tab = ScreenshotLaunchConfig.selectedTab {
                selectedTab = tab
            }
            #endif
        }
    }
}
