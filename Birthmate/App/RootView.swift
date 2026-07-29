import SwiftUI

struct RootView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore

    var body: some View {
        if birthdateStore.hasBirthdate {
            MainTabView()
        } else {
            OnboardingView()
        }
    }
}
