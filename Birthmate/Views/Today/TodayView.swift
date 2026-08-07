import SwiftUI

struct TodayView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var notificationManager: NotificationManager
    @Binding var selectedTab: AppTab
    @AppStorage(NotificationPromptStore.seenStorageKey) private var hasSeenNotificationPrompt = false
    @StateObject private var viewModel = TodayViewModel()
    @State private var showNotificationPrompt = false

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
                if viewModel.isRefreshing {
                    ToolbarItem(placement: .topBarTrailing) {
                        ProgressView()
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
        .sheet(isPresented: $showNotificationPrompt) {
            if let month = birthdateStore.month, let day = birthdateStore.day {
                DailyReminderPromptView(
                    dateLabel: formattedDate,
                    month: month,
                    day: day
                ) {
                    showNotificationPrompt = false
                    hasSeenNotificationPrompt = true
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onChange(of: viewModel.featuredPerson?.id) { _, _ in evaluateNotificationPrompt() }
        .onChange(of: viewModel.featuredEvent?.id) { _, _ in evaluateNotificationPrompt() }
    }

    private func evaluateNotificationPrompt() {
        #if DEBUG
        if ScreenshotLaunchConfig.skipNotificationPrompt { return }
        #endif
        guard AppLaunchStore.launchCount >= 2,
              !hasSeenNotificationPrompt,
              !notificationManager.isEnabled,
              !showNotificationPrompt,
              viewModel.featuredPerson != nil || viewModel.featuredEvent != nil else { return }

        showNotificationPrompt = true
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

                statsStorySection
                exploreSection

                LastUpdatedLabel(date: viewModel.lastUpdated)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)

                WikiAttributionFooter()
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
            return "Today's picks from everyone born on \(formattedDate)."
        }
        return "Daily highlights from your day — pull down or tap Another to shuffle."
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(greeting)
                .font(.title2.bold())

            Text(headerSubtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private func featuredPersonSection(_ person: OnThisDayItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            featuredSectionHeader(
                title: "Featured Birthmate",
                systemImage: "person.crop.circle.fill",
                actionTitle: "Another"
            ) {
                viewModel.showAnotherFeaturedPerson()
            }
            .sensoryFeedback(.selection, trigger: viewModel.featuredPerson?.id)

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
                actionTitle: "Another"
            ) {
                viewModel.showAnotherFeaturedEvent()
            }
            .sensoryFeedback(.selection, trigger: viewModel.featuredEvent?.id)

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
                .buttonStyle(.bordered)
                .tint(BirthmateTheme.accent)
                .controlSize(.small)
        }
    }

    private var exploreSection: some View {
        Button {
            selectedTab = .people
        } label: {
            ExploreRow(
                title: "See all birthmates",
                subtitle: "\(viewModel.birthCount.formatted()) people share \(formattedDate)",
                systemImage: "person.2.fill"
            )
        }
        .buttonStyle(.plain)
    }

    private var statsStorySection: some View {
        Group {
            if viewModel.birthCount > 0 {
                Text("You share **\(formattedDate)** with **\(viewModel.birthCount.formatted())** birthmates and **\(viewModel.eventCount.formatted())** historical moments.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(BirthmateTheme.cardPadding)
                    .background(
                        RoundedRectangle(cornerRadius: BirthmateTheme.radiusCard, style: .continuous)
                            .fill(BirthmateTheme.cream.opacity(0.5))
                    )
            }
        }
    }

    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Circle()
                        .fill(Color(.secondarySystemGroupedBackground))
                        .frame(width: 88, height: 88)
                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .frame(height: 18)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .frame(width: 100, height: 14)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.secondarySystemGroupedBackground))
                            .frame(height: 40)
                    }
                }
                .padding(BirthmateTheme.cardPadding)
                .background(BirthmateTheme.heroCardBackground())

                RoundedRectangle(cornerRadius: BirthmateTheme.radiusHero)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .frame(height: 100)
            }
            .padding(BirthmateTheme.screenPadding)
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
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                PersonThumbnailView(
                    urlString: item.primaryPage?.thumbnail?.source,
                    wikiTitle: item.primaryPage?.title,
                    size: 88
                )

                VStack(alignment: .leading, spacing: 6) {
                    Text(item.displayName)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                        .lineLimit(2)

                    if let year = item.birthYear {
                        Text("Born \(String(year))")
                            .font(.subheadline.weight(.semibold))
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
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .background(BirthmateTheme.heroCardBackground())
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
        .background(BirthmateTheme.heroCardBackground())
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
        .environmentObject(NotificationManager())
}

struct TodayPersonRoute: Hashable {
    let item: OnThisDayItem
}

struct TodayEventRoute: Hashable {
    let item: OnThisDayItem
}
