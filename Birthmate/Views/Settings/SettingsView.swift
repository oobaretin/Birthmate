import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var notificationManager: NotificationManager
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if let month = birthdateStore.month, let day = birthdateStore.day {
                        HStack {
                            Image(systemName: "gift.fill")
                                .foregroundStyle(BirthmateTheme.accent)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(DateFormatting.birthdate(month: month, day: day))
                                    .font(.headline)
                                Text("Your birth month and day")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                } header: {
                    Text("Your Birthday")
                }

                Section {
                    Button("Change Birthday", role: .destructive) {
                        Label("Daily reminder", systemImage: "bell.fill")
                    }
                    .onChange(of: notificationManager.isEnabled) { _, enabled in
                        Task {
                            await notificationManager.handleToggleChange(
                                enabled: enabled,
                                month: birthdateStore.month,
                                day: birthdateStore.day
                            )
                        }
                    }

                    if notificationManager.isEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: $notificationManager.reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: notificationManager.reminderTime) { _, _ in
                            Task {
                                guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
                                await notificationManager.scheduleDailyReminder(month: month, day: day)
                            }
                        }

                        Text("You'll get a reminder every day at \(notificationManager.reminderTimeLabel).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Notifications")
                }

                Section {
                    Button("Change Birthday", role: .destructive) {
                        showResetConfirmation = true
                    }
                }

                Section {
                    WikiAttributionFooter()
                        .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog(
                "Change your birthday?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Change Birthday", role: .destructive) {
                    notificationManager.cancelReminders()
                    NotificationPromptStore.reset()
                    birthdateStore.clear()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BirthdateStore())
        .environmentObject(NotificationManager())
}
