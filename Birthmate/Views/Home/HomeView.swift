import SwiftUI

struct HomeView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @EnvironmentObject var profileStore: ProfileStore
    @StateObject private var viewModel = HomeBirthsViewModel()
    @State private var searchText = ""
    @State private var randomPerson: OnThisDayItem?

    private var formattedDate: String {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return "" }
        return DateFormatting.birthdate(month: month, day: day)
    }

    private var displaySections: [BirthSection] {
        viewModel.filteredSections(
            matching: searchText,
            favoriteWikiTitles: profileStore.favoriteWikiTitles
        )
    }

    private var visibleCount: Int {
        displaySections.reduce(0) { $0 + $1.items.count }
    }

    private var birthmatesSubtitle: String {
        if viewModel.isLoadingMore {
            return "\(viewModel.totalCount) birthmates on your day"
        }
        return "\(visibleCount) of \(viewModel.totalCount) on your day"
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allItems.isEmpty {
                    skeletonList
                } else if let error = viewModel.errorMessage, viewModel.allItems.isEmpty {
                    FeedErrorView(message: error) { await reload(force: true) }
                } else if viewModel.allItems.isEmpty {
                    FeedEmptyView(
                        title: "No Results",
                        systemImage: "person.crop.circle.badge.questionmark",
                        message: "No births with a recorded year were found for this date."
                    )
                } else if viewModel.filter == .favorites && profileStore.favoriteWikiTitles.isEmpty {
                    FeedEmptyView(
                        title: "No Favorites Yet",
                        systemImage: "heart",
                        message: "Tap Favorite on any birthmate to save them here."
                    )
                } else if visibleCount == 0 {
                    FeedEmptyView(
                        title: "No Matches",
                        systemImage: "magnifyingglass",
                        message: "Try a different name, keyword, or filter."
                    )
                } else {
                    List {
                        summaryHeader

                        ForEach(displaySections) { section in
                            Section {
                                ForEach(section.items) { item in
                                    NavigationLink(value: item) {
                                        PersonRow(item: item)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowSeparator(.visible)
                                }
                            } header: {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(section.title)
                                    Text(section.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .refreshable { await reload(force: true) }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("Birthmates")
                            .font(.headline)
                        Text(birthmatesSubtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if viewModel.isLoadingMore {
                            Text("Finding more birthmates…")
                                .font(.caption2)
                                .foregroundStyle(BirthmateTheme.accent)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search by name")
            .navigationDestination(for: OnThisDayItem.self) { item in
                PersonDetailView(item: item, dateLabel: formattedDate)
            }
            .sheet(item: $randomPerson) { person in
                NavigationStack {
                    PersonDetailView(item: person, dateLabel: formattedDate)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { randomPerson = nil }
                            }
                        }
                }
            }
        }
        .task { await reload() }
    }

    private var summaryHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if let month = birthdateStore.month, let day = birthdateStore.day {
                    BirthdayBanner(month: month, day: day)
                }

                HStack(spacing: 16) {
                    StatBadge(value: viewModel.totalCount, label: "Total", icon: "person.2.fill")
                    StatBadge(value: viewModel.livingCount, label: "Living", icon: "heart.fill")
                    StatBadge(
                        value: viewModel.totalCount - viewModel.livingCount,
                        label: "Historical",
                        icon: "book.fill"
                    )
                }

                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(BirthFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.filter == .favorites {
                    Text("\(profileStore.favoriteWikiTitles.count) saved on this device")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    randomPerson = viewModel.allItems.randomElement()
                } label: {
                    Label("Random Birthmate", systemImage: "dice.fill")
                        .font(.subheadline.weight(.medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(BirthmateTheme.accent)

                LastUpdatedLabel(date: viewModel.lastUpdated)
            }
            .padding(.vertical, 4)
        }
    }

    private var skeletonList: some View {
        List(0..<8, id: \.self) { _ in
            SkeletonPersonRow()
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
    }

    private func reload(force: Bool = false) async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        await viewModel.load(month: month, day: day, forceRefresh: force)
    }
}

struct PersonRow: View {
    let item: OnThisDayItem

    private var snippet: String {
        if let extract = item.primaryPage?.extract, !extract.isEmpty {
            return WikiFormatting.plainText(from: extract)
        }
        let parts = item.text.components(separatedBy: ",")
        return parts.dropFirst().joined(separator: ",").trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            PersonThumbnailView(
                urlString: item.primaryPage?.thumbnail?.source,
                wikiTitle: item.primaryPage?.title
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.displayName)
                        .font(.headline)
                        .lineLimit(2)

                    if item.isLiving {
                        Text("Living")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BirthmateTheme.accent.opacity(0.15))
                            .foregroundStyle(BirthmateTheme.accent)
                            .clipShape(Capsule())
                    }
                }

                if let year = item.birthYear {
                    Text("Born \(String(year))")
                        .font(.subheadline)
                        .foregroundStyle(BirthmateTheme.accent)
                }

                if !snippet.isEmpty {
                    Text(snippet)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
        .id(item.id)
    }
}

struct PersonDetailView: View {
    let item: OnThisDayItem
    let dateLabel: String
    @EnvironmentObject var profileStore: ProfileStore
    @EnvironmentObject var authStore: AuthStore
    @EnvironmentObject var birthdateStore: BirthdateStore
    @State private var loadedExtract: String?
    @State private var actionMessage: String?
    @StateObject private var socialActions = CommunityViewModel()

    private var bodyText: String {
        if let loadedExtract { return loadedExtract }
        if let extract = item.primaryPage?.extract, !extract.isEmpty {
            return WikiFormatting.plainText(from: extract)
        }
        return WikiFormatting.plainText(from: item.text)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PersonHeroImageView(
                    urlString: item.primaryPage?.originalImage?.source ?? item.primaryPage?.thumbnail?.source,
                    wikiTitle: item.primaryPage?.title
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        if let year = item.birthYear {
                            Text("Born \(String(year))")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BirthmateTheme.accent)
                        }
                        if item.isLiving {
                            Label("Living", systemImage: "heart.fill")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(BirthmateTheme.accent)
                        }
                    }

                    Text(item.displayName)
                        .font(.title.bold())

                    Text(bodyText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Button {
                            Task { await toggleFavorite() }
                        } label: {
                            Label(
                                profileStore.isFavorite(item) ? "Favorited" : "Favorite",
                                systemImage: profileStore.isFavorite(item) ? "heart.fill" : "heart"
                            )
                            .font(.subheadline.weight(.medium))
                        }
                        .tint(BirthmateTheme.accent)

                        Button {
                            Task { await setFamousTwin() }
                        } label: {
                            Label("My famous twin", systemImage: "star.fill")
                                .font(.subheadline.weight(.medium))
                        }
                        .tint(BirthmateTheme.accent)
                    }

                    ShareBirthmateCardLink(item: item, dateLabel: dateLabel)

                    if let urlString = item.primaryPage?.contentUrls?.desktop?.page,
                       let url = URL(string: urlString) {
                        Link(destination: url) {
                            Label("Read more on Wikipedia", systemImage: "arrow.up.right.square")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .actionFeedback($actionMessage)
        .task {
            if item.primaryPage?.extract == nil {
                loadedExtract = await WikipediaSummaryService.shared.fetchExtract(for: item)
            }
        }
    }

    private func toggleFavorite() async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        let wasFavorite = profileStore.isFavorite(item)
        await socialActions.toggleFavorite(item, profile: profileStore, authStore: authStore)
        actionMessage = wasFavorite ? "Removed from favorites" : "Added to favorites"
        _ = month
        _ = day
    }

    private func setFamousTwin() async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        await socialActions.setFamousTwin(item, month: month, day: day, profile: profileStore, authStore: authStore)
        actionMessage = "\(item.displayName) is your famous twin"
    }
}

#Preview {
    HomeView()
        .environmentObject(BirthdateStore())
        .environmentObject(ProfileStore())
}
