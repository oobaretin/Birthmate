import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .today
    @AppStorage(WelcomeTipsStore.seenStorageKey) private var hasSeenWelcomeTips = false

    private var showWelcomeTips: Binding<Bool> {
        Binding(
            get: { !hasSeenWelcomeTips },
            set: { isPresented in
                if !isPresented {
                    hasSeenWelcomeTips = true
                }
            }
        )
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sparkles") }
                .tag(AppTab.today)

            CommunityView()
                .tabItem { Label("Circle", systemImage: "person.3.fill") }
                .tag(AppTab.community)

            HomeView()
                .tabItem { Label("Birthmates", systemImage: "person.2.fill") }
                .tag(AppTab.people)

            OnThisDayView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(AppTab.history)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(AppTab.settings)
        }
        .tint(BirthmateTheme.accent)
        .sheet(isPresented: showWelcomeTips) {
            WelcomeTipsView {
                hasSeenWelcomeTips = true
            }
            .presentationDragIndicator(.visible)
            .presentationDetents([.large])
        }
        #if DEBUG
        .onAppear {
            if ScreenshotLaunchConfig.showWelcome {
                hasSeenWelcomeTips = false
            } else if ScreenshotLaunchConfig.skipWelcome {
                hasSeenWelcomeTips = true
            }
            if let tab = ScreenshotLaunchConfig.selectedTab {
                selectedTab = tab
            }
        }
        #endif
    }
}
