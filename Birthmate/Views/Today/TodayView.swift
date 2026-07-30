import SwiftUI

struct TodayView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var authStore: AuthStore
    @Binding var selectedTab: AppTab
    @StateObject private var viewModel = TodayViewModel()
    @StateObject private var activityViewModel = ActivityViewModel()

    private var formattedDate: String {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return "" }
        return DateFormatting.birthdate(month: month, day: day)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        default: return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.featuredPerson == nil && viewModel.featuredEvent == nil {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.featuredPerson == nil && viewModel.featuredEvent == nil {
                    FeedErrorView(message: error) { await reload(forceRefresh: true) }
                } else {
                    scrollContent
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Today")
                            .font(.headline)
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationDestination(for: TodayPersonRoute.self) { route in
                PersonDetailView(item: route.item, dateLabel: formattedDate)
            }
            .navigationDestination(for: TodayEventRoute.self) { route in
                EventDetailView(
                    item: route.item,
                    dateLabel: formattedDate,
                    isDeath: viewModel.isDeath(route.item)
                )
            }
        }
        .task(id: todayRefreshKey) { await reload(forceRefresh: false) }
        .task(id: profileStore.discoverOthers) {
            await activityViewModel.load(
                authStore: authStore,
                discoverOthers: profileStore.discoverOthers
            )
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                if let person = viewModel.featuredPerson {
                    featuredPersonSection(person)
                }

                if let event = viewModel.featuredEvent {
                    featuredEventSection(event)
                }

                statsSection
                activitySection
                exploreSection

                LastUpdatedLabel(date: viewModel.lastUpdated)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
            .padding()
        }
        .refreshable { await reload(forceRefresh: true) }
    }

    private var todayRefreshKey: String {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return "" }
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return "\(formatter.string(from: Date()))-\(month)-\(day)"
    }

    private var isBirthdayToday: Bool {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return false }
        let calendar = Calendar.current
        let now = Date()
        return calendar.component(.month, from: now) == month
            && calendar.component(.day, from: now) == day
    }

    private var headerSubtitle: String {
        if isBirthdayToday {
            return "Happy birthday! Random highlights for \(formattedDate) — your day."
        }
        return "On \(formattedDate). Random highlights from your day — pull down to shuffle."
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greeting)
                .font(.title2.bold())

            Text(headerSubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let month = birthdateStore.month, let day = birthdateStore.day {
                BirthdayBanner(month: month, day: day)
            }
        }
    }

    @ViewBuilder
    private func featuredPersonSection(_ person: OnThisDayItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            featuredSectionHeader(
                title: "Featured Birthmate",
                systemImage: "person.crop.circle.fill",
                actionTitle: "Shuffle"
            ) {
                viewModel.showAnotherFeaturedPerson()
            }

            NavigationLink(value: TodayPersonRoute(item: person)) {
                FeaturedPersonCard(item: person)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Featured birthmate, \(person.displayName)")
        }
    }

    @ViewBuilder
    private func featuredEventSection(_ event: OnThisDayItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            featuredSectionHeader(
                title: "On This Day in History",
                systemImage: "clock.fill",
                actionTitle: "Shuffle"
            ) {
                viewModel.showAnotherFeaturedEvent()
            }

            NavigationLink(value: TodayEventRoute(item: event)) {
                FeaturedEventCard(item: event, isDeath: viewModel.isDeath(event))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                viewModel.isDeath(event)
                    ? "Featured death on this day, \(event.displayText)"
                    : "Featured event, \(event.displayText)"
            )
        }
    }

    private func featuredSectionHeader(
        title: String,
        systemImage: String,
        actionTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .center) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BirthmateTheme.accent)

            Spacer()

            Button(actionTitle, action: action)
                .font(.caption.weight(.semibold))
                .foregroundStyle(BirthmateTheme.accent)
        }
    }

    private var activitySection: some View {
        Group {
            if profileStore.discoverOthers, !activityViewModel.events.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label(
                        activityViewModel.isDemoMode ? "Preview activity" : "Your activity",
                        systemImage: "bell.fill"
                    )
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BirthmateTheme.accent)

                    ForEach(activityViewModel.events.prefix(3)) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.title)
                                .font(.subheadline.weight(.medium))
                            if let detail = event.detail {
                                Text(detail)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color(.secondarySystemGroupedBackground))
                        )
                    }
                }
            }
        }
    }

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatBadge(value: viewModel.birthCount, label: "Birthmates", icon: "person.2.fill")
            StatBadge(value: viewModel.highlightCount, label: "Highlights", icon: "star.fill")
            StatBadge(value: viewModel.eventCount, label: "Events", icon: "book.fill")
        }
    }

    private var exploreSection: some View {
        VStack(spacing: 12) {
            Button {
                selectedTab = .community
            } label: {
                ExploreRow(
                    title: profileStore.isDemoCommunityMode ? "Preview Birthday Circle" : "See birthday twins",
                    subtitle: profileStore.isDemoCommunityMode
                        ? "Sample people who share your day"
                        : "Meet others in Birthday Circle",
                    systemImage: "person.3.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedTab = .people
            } label: {
                ExploreRow(
                    title: "Explore all birthmates",
                    subtitle: "\(viewModel.birthCount) people share your day",
                    systemImage: "person.2.fill"
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedTab = .history
            } label: {
                ExploreRow(
                    title: "Explore history",
                    subtitle: "\(viewModel.eventCount) events on your day",
                    systemImage: "clock.fill"
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 180)
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 140)
            }
            .padding()
        }
        .redacted(reason: .placeholder)
    }

    private func reload(forceRefresh: Bool = false) async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        await viewModel.load(month: month, day: day, forceRefresh: forceRefresh)
    }
}

struct FeaturedPersonCard: View {
    let item: OnThisDayItem

    private var snippet: String {
        if let extract = item.primaryPage?.extract, !extract.isEmpty {
            return WikiFormatting.plainText(from: extract)
        }
        return WikiFormatting.plainText(from: item.text)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            PersonThumbnailView(
                urlString: item.primaryPage?.thumbnail?.source,
                wikiTitle: item.primaryPage?.title
            )
            .frame(width: 72, height: 72)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let year = item.birthYear {
                    Text("Born \(String(year))")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(BirthmateTheme.accent)
                }

                if !snippet.isEmpty {
                    Text(snippet)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
                .padding(.top, 4)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(BirthmateTheme.cardBackground())
    }
}

struct FeaturedEventCard: View {
    let item: OnThisDayItem
    var isDeath: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                if isDeath {
                    HistoryDeathMarker()
                }
                if let year = item.eventYear {
                    Text(String(year))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(isDeath ? .secondary : BirthmateTheme.accent)
                }
            }
            .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.displayText)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(BirthmateTheme.cardBackground())
    }
}

struct ExploreRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(BirthmateTheme.accent)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

#Preview {
    TodayView(selectedTab: .constant(.today))
        .environmentObject(BirthdateStore())
        .environmentObject(ProfileStore())
        .environmentObject(AuthStore())
}

struct TodayPersonRoute: Hashable {
    let item: OnThisDayItem
}

struct TodayEventRoute: Hashable {
    let item: OnThisDayItem
}
