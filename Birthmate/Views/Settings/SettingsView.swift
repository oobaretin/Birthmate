import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var authStore: AuthStore
    @State private var showResetConfirmation = false
    @State private var profileSyncMessage: String?

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

                if profileStore.requiresSignIn {
                    Section {
                        if authStore.isSignedIn {
                            SignedInBadge()
                            Button("Sign Out", role: .destructive) {
                                authStore.signOut()
                            }
                        } else {
                            SignInWithAppleButtonView()
                            if let error = authStore.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                    } header: {
                        Text("Account")
                    } footer: {
                        Text("Sign in with Apple to join Birthday Circle and connect with friends.")
                    }
                }

                Section {
                    TextField("Display name", text: $profileStore.displayName)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()

                    if let twin = profileStore.famousTwinName {
                        LabeledContent("Famous twin", value: twin)
                    }

                    Toggle(isOn: $profileStore.isDiscoverable) {
                        Label("Appear in Birthday Circle", systemImage: "person.crop.circle.badge.checkmark")
                    }

                    Toggle(isOn: $profileStore.discoverOthers) {
                        Label("Discover others on my day", systemImage: "person.3.fill")
                    }

                    if profileStore.isDiscoverable || profileStore.discoverOthers {
                        Text("Only your month, day, and display name are shared. Birth year is never uploaded.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let profileSyncMessage {
                        Text(profileSyncMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Birthday Circle")
                } footer: {
                    if BirthmateSecrets.isCommunityConfigured {
                        Text("Live community is enabled.")
                    } else {
                        Text("Demo mode shows sample people until Supabase is configured.")
                    }
                }

                Section {
                    Toggle(isOn: $notificationManager.isEnabled) {
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
            }
            .navigationTitle("Settings")
            .onChange(of: profileStore.displayName) { _, _ in syncProfile() }
            .onChange(of: profileStore.isDiscoverable) { _, _ in syncProfile() }
            .onChange(of: profileStore.discoverOthers) { _, _ in syncProfile() }
            .onChange(of: profileStore.famousTwinName) { _, _ in syncProfile() }
            .confirmationDialog(
                "Change your birthday?",
                isPresented: $showResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Change Birthday", role: .destructive) {
                    notificationManager.cancelReminders()
                    birthdateStore.clear()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func syncProfile() {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }

        Task {
            do {
                let viewModel = CommunityViewModel()
                try await viewModel.syncOwnProfile(
                    month: month,
                    day: day,
                    profile: profileStore,
                    authStore: authStore
                )
                profileSyncMessage = profileStore.isDiscoverable
                    ? "Your profile is visible in Birthday Circle."
                    : "You are hidden from Birthday Circle."
            } catch {
                profileSyncMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BirthdateStore())
        .environmentObject(NotificationManager())
        .environmentObject(ProfileStore())
        .environmentObject(AuthStore())
}
