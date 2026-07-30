import SwiftUI

struct WelcomeTipsView: View {
    @EnvironmentObject private var birthdateStore: BirthdateStore
    var onComplete: () -> Void

    private var birthdaySubtitle: String? {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return nil }
        return "Your day is \(DateFormatting.birthdate(month: month, day: day))"
    }

    var body: some View {
        ZStack {
            BirthmateTheme.onboardingGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        header

                        VStack(spacing: 12) {
                            tipCard(
                                icon: "sparkles",
                                title: "Today",
                                message: "Daily highlights — a featured birthmate and history from your day."
                            )
                            tipCard(
                                icon: "person.2.fill",
                                title: "Birthmates",
                                message: "Browse everyone born on your birthday. Tap a name to read more."
                            )
                            tipCard(
                                icon: "clock.fill",
                                title: "History",
                                message: "Events and milestones that happened on your day."
                            )
                            tipCard(
                                icon: "person.3.fill",
                                title: "Circle",
                                message: "Preview Birthday Circle — sample people who share your day."
                            )
                            tipCard(
                                icon: "heart.fill",
                                title: "Save favorites",
                                message: "Tap Favorite on any birthmate to save them. Filter by Favorites on the Birthmates tab."
                            )
                        }

                        Text("You can change your birthday and notifications anytime in Settings.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                }

                Button(action: onComplete) {
                    Text("Get started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BirthmateTheme.accent.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
            }
        }
    }

    private var header: some View {
        VStack(spacing: 14) {
            AppLogoView(size: 96, cornerRadius: 21)

            Text("Welcome to Birthmate")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            if let birthdaySubtitle {
                Text(birthdaySubtitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(BirthmateTheme.accent)
            }

            Text("Here is a quick tour of what you can do.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    private func tipCard(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BirthmateTheme.accent)
                .frame(width: 36, height: 36)
                .background(BirthmateTheme.accent.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

enum WelcomeTipsStore {
    static let seenStorageKey = "birthmate_has_seen_welcome_tips"

    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: seenStorageKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenStorageKey)
    }
}

#Preview {
    WelcomeTipsView(onComplete: {})
        .environmentObject(BirthdateStore())
}
