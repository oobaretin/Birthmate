import SwiftUI

struct WelcomeTipsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    tipRow(
                        icon: "sparkles",
                        title: "Today",
                        message: "Your daily highlights — a featured birthmate and history from your day."
                    )
                    tipRow(
                        icon: "person.2.fill",
                        title: "Birthmates",
                        message: "Browse everyone born on your birthday. Tap a name to read more."
                    )
                    tipRow(
                        icon: "clock.fill",
                        title: "History",
                        message: "Events and milestones that happened on your day."
                    )
                    tipRow(
                        icon: "person.3.fill",
                        title: "Circle",
                        message: "Preview Birthday Circle — sample people who share your day."
                    )
                    tipRow(
                        icon: "heart.fill",
                        title: "Save favorites",
                        message: "Tap Favorite on any birthmate to save them. Filter by Favorites on the Birthmates tab."
                    )
                } header: {
                    Text("Quick tour")
                } footer: {
                    Text("You can change your birthday and notifications anytime in Settings.")
                }
            }
            .navigationTitle("Welcome")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Got it") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func tipRow(icon: String, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(BirthmateTheme.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 4)
    }
}

enum WelcomeTipsStore {
    private static let seenKey = "birthmate_has_seen_welcome_tips"

    static var shouldShow: Bool {
        !UserDefaults.standard.bool(forKey: seenKey)
    }

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenKey)
    }
}

#Preview {
    WelcomeTipsView()
}
