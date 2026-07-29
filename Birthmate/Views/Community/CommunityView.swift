import SwiftUI

struct CommunityView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var authStore: AuthStore
    @StateObject private var viewModel = CommunityViewModel()
    @State private var pendingInviteHandled = false

    private var formattedDate: String {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return "" }
        return DateFormatting.birthdate(month: month, day: day)
    }

    var body: some View {
        NavigationStack {
            Group {
                if needsSignIn {
                    signInState
                } else if !profileStore.canBrowseCommunity {
                    disabledState
                } else if viewModel.isLoading && viewModel.members.isEmpty {
                    loadingState
                } else if let error = viewModel.errorMessage, viewModel.members.isEmpty {
                    FeedErrorView(message: error, retry: reload)
                } else {
                    memberList
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Birthday Circle")
                            .font(.headline)
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    if authStore.isSignedIn, let userID = authStore.userID {
                        ShareLink(item: inviteURL(for: userID)) {
                            Image(systemName: "person.badge.plus")
                        }
                        .accessibilityLabel("Invite friends")
                    }
                }
            }
        }
        .task(id: refreshToken) {
            await reload()
            await handlePendingInvite()
        }
    }

    private var needsSignIn: Bool {
        profileStore.requiresSignIn && !authStore.isSignedIn &&
        (profileStore.isDiscoverable || profileStore.discoverOthers)
    }

    private var refreshToken: String {
        [
            birthdateStore.month.map(String.init) ?? "",
            birthdateStore.day.map(String.init) ?? "",
            profileStore.discoverOthers.description,
            profileStore.isDiscoverable.description,
            profileStore.displayName,
            authStore.userID ?? "",
            profileStore.famousTwinWikiTitle ?? ""
        ].joined(separator: "-")
    }

    private var signInState: some View {
        VStack(spacing: 20) {
            FeedEmptyView(
                title: "Sign In Required",
                systemImage: "person.crop.circle.badge.checkmark",
                message: "Sign in with Apple to join Birthday Circle and connect with real people on your day."
            )
            SignInWithAppleButtonView()
                .padding(.horizontal, 24)
            if authStore.isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Connecting…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let status = authStore.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundStyle(BirthmateTheme.accent)
                    .padding(.horizontal)
            }
            if let error = authStore.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal)
            }
        }
        .padding()
    }

    private var disabledState: some View {
        VStack(spacing: 20) {
            FeedEmptyView(
                title: "Birthday Circle is Off",
                systemImage: "person.3.fill",
                message: "Turn on Birthday Circle to preview sample people who share your day."
            )

            Button {
                profileStore.discoverOthers = true
            } label: {
                Text("Turn On Birthday Circle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .tint(BirthmateTheme.accent)
            .padding(.horizontal, 24)
        }
        .padding()
    }

    private var memberList: some View {
        List {
            if viewModel.isDemoMode {
                Section {
                    Label {
                        Text("Preview mode — sample people shown until live sign-in is available.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } icon: {
                        Image(systemName: "eye.fill")
                            .foregroundStyle(BirthmateTheme.accent)
                    }
                }
            }

            if !viewModel.pendingRequests.isEmpty {
                Section("Friend requests") {
                    ForEach(viewModel.pendingRequests) { request in
                        HStack {
                            Text("Someone wants to connect")
                                .font(.subheadline)
                            Spacer()
                            Button("Accept") {
                                Task { await viewModel.respondToFriendRequest(request, accept: true, authStore: authStore, profile: profileStore) }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(BirthmateTheme.accent)
                            Button("Decline") {
                                Task { await viewModel.respondToFriendRequest(request, accept: false, authStore: authStore, profile: profileStore) }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            Section {
                if let month = birthdateStore.month, let day = birthdateStore.day {
                    BirthdayBanner(month: month, day: day)
                }

                if let twin = profileStore.famousTwinName {
                    Label("Your famous twin: \(twin)", systemImage: "star.fill")
                        .font(.subheadline)
                        .foregroundStyle(BirthmateTheme.accent)
                }

                Text("\(viewModel.members.count) \(viewModel.members.count == 1 ? "person" : "people") celebrating \(formattedDate)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("On your day") {
                if viewModel.members.isEmpty {
                    Text("No sample people to show right now. Pull to refresh.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.members) { member in
                        CommunityMemberRow(
                            member: member,
                            dateLabel: formattedDate,
                            isDemoMode: viewModel.isDemoMode,
                            requestSent: viewModel.demoSentRequestIDs.contains(member.id)
                        ) {
                            Task { await viewModel.sendFriendRequest(to: member, authStore: authStore, profile: profileStore) }
                        }
                    }
                }
            }

            if !viewModel.activity.isEmpty {
                Section("Recent activity") {
                    ForEach(viewModel.activity) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.subheadline.weight(.medium))
                            if let detail = event.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let lastSyncedAt = viewModel.lastSyncedAt {
                Section {
                    LastUpdatedLabel(date: lastSyncedAt)
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await reload() }
    }

    private var loadingState: some View {
        List(0..<4, id: \.self) { _ in
            HStack(spacing: 12) {
                Circle().fill(Color(.systemGray5)).frame(width: 44, height: 44)
                VStack(alignment: .leading, spacing: 6) {
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(width: 120, height: 14)
                    RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(width: 180, height: 12)
                }
            }
            .redacted(reason: .placeholder)
        }
        .listStyle(.insetGrouped)
    }

    private func reload() async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        await viewModel.refresh(month: month, day: day, profile: profileStore, authStore: authStore)
    }

    private func handlePendingInvite() async {
        guard !pendingInviteHandled,
              let userID = authStore.pendingInviteUserID,
              authStore.isSignedIn,
              let month = birthdateStore.month,
              let day = birthdateStore.day else { return }

        pendingInviteHandled = true
        let member = CommunityMember(id: userID, displayName: "Friend", birthMonth: month, birthDay: day)
        await viewModel.sendFriendRequest(to: member, authStore: authStore, profile: profileStore)
        authStore.pendingInviteUserID = nil
    }

    private func inviteURL(for userID: String) -> URL {
        URL(string: "birthmate://friend?user=\(userID)")!
    }
}

struct CommunityMemberRow: View {
    let member: CommunityMember
    let dateLabel: String
    var isDemoMode: Bool = false
    var requestSent: Bool = false
    var onAddFriend: (() -> Void)?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(BirthmateTheme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Text(member.initials)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BirthmateTheme.accent)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(member.displayName)
                        .font(.body.weight(.semibold))
                    if isDemoMode {
                        Text("Sample")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(.systemGray5))
                            .foregroundStyle(.secondary)
                            .clipShape(Capsule())
                    }
                }
                Text("Shares \(dateLabel)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let twin = member.famousTwinName {
                    Text("Famous twin: \(twin)")
                        .font(.caption)
                        .foregroundStyle(BirthmateTheme.accent)
                }
            }

            Spacer()

            if requestSent {
                Text("Sent")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            } else if let onAddFriend {
                Button(isDemoMode ? "Connect" : "Add", action: onAddFriend)
                    .buttonStyle(.bordered)
                    .tint(BirthmateTheme.accent)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CommunityView()
        .environmentObject(BirthdateStore())
        .environmentObject(ProfileStore())
        .environmentObject(AuthStore())
}
