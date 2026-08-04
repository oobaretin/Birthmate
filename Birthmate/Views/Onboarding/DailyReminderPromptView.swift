import SwiftUI

enum NotificationPromptStore {
    static let seenStorageKey = "birthmate_has_seen_notification_prompt"

    static func markSeen() {
        UserDefaults.standard.set(true, forKey: seenStorageKey)
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: seenStorageKey)
    }
}

struct DailyReminderPromptView: View {
    @EnvironmentObject private var notificationManager: NotificationManager
    let dateLabel: String
    let month: Int
    let day: Int
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 52))
                .foregroundStyle(BirthmateTheme.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 10) {
                Text("Daily highlight?")
                    .font(.title2.bold())

                Text("Get a gentle reminder each day to explore birthmates and history for \(dateLabel).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            DatePicker(
                "Reminder time",
                selection: $notificationManager.reminderTime,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.compact)
            .padding(.horizontal, 8)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    Task {
                        notificationManager.isEnabled = true
                        await notificationManager.scheduleDailyReminder(month: month, day: day)
                        NotificationPromptStore.markSeen()
                        onComplete()
                    }
                } label: {
                    Text("Enable daily reminder")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(BirthmateTheme.accent.gradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                Button("Not now") {
                    NotificationPromptStore.markSeen()
                    onComplete()
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .background(BirthmateTheme.onboardingGradient.ignoresSafeArea())
    }
}

#Preview {
    DailyReminderPromptView(dateLabel: "July 29", month: 7, day: 29, onComplete: {})
        .environmentObject(NotificationManager())
}
