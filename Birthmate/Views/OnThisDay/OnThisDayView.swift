import SwiftUI

struct OnThisDayView: View {
    @EnvironmentObject var birthdateStore: BirthdateStore
    @StateObject private var viewModel = OnThisDayViewModel()
    @State private var searchText = ""

    private var formattedDate: String {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return "" }
        return DateFormatting.birthdate(month: month, day: day)
    }

    private var displaySections: [FeedSection] {
        viewModel.displaySections(matching: searchText)
    }

    private var visibleCount: Int {
        displaySections.reduce(0) { $0 + $1.items.count }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allEvents.isEmpty && viewModel.allSelected.isEmpty && viewModel.allDeaths.isEmpty {
                    skeletonList
                } else if let error = viewModel.errorMessage, viewModel.allEvents.isEmpty && viewModel.allSelected.isEmpty && viewModel.allDeaths.isEmpty {
                    FeedErrorView(message: error, retry: reload)
                } else if viewModel.allEvents.isEmpty && viewModel.allSelected.isEmpty && viewModel.allDeaths.isEmpty {
                    FeedEmptyView(
                        title: "No Events Found",
                        systemImage: "clock.badge.questionmark",
                        message: "Nothing notable recorded for this date."
                    )
                } else if visibleCount == 0 {
                    FeedEmptyView(
                        title: "No Matches",
                        systemImage: "magnifyingglass",
                        message: "Try a different keyword or filter."
                    )
                } else {
                    List {
                        summaryHeader

                        ForEach(displaySections) { section in
                            Section {
                                ForEach(section.items) { item in
                                    NavigationLink(value: item) {
                                        if viewModel.allSelected.contains(where: { $0.id == item.id }) && viewModel.filter != .events {
                                            SelectedEventRow(item: item)
                                        } else {
                                            EventRow(item: item)
                                        }
                                    }
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
                    .refreshable { await reload() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 2) {
                        Text("History")
                            .font(.headline)
                        Text("\(visibleCount) of \(viewModel.totalCount) on your day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search events")
            .navigationDestination(for: OnThisDayItem.self) { item in
                EventDetailView(item: item, dateLabel: formattedDate)
            }
        }
        .task { await reload() }
    }

    @ViewBuilder
    private var summaryHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                if let month = birthdateStore.month, let day = birthdateStore.day {
                    BirthdayBanner(month: month, day: day)
                }

                HStack(spacing: 12) {
                    StatBadge(value: viewModel.totalCount, label: "Total", icon: "clock.fill")
                    StatBadge(value: viewModel.highlightCount, label: "Highlights", icon: "star.fill")
                    StatBadge(value: viewModel.allEvents.count, label: "Events", icon: "book.fill")
                }

                Picker("Filter", selection: $viewModel.filter) {
                    ForEach(EventFilter.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)

                LastUpdatedLabel(date: viewModel.lastUpdated)
            }
            .padding(.vertical, 4)
        }
    }

    private var skeletonList: some View {
        List(0..<8, id: \.self) { _ in
            SkeletonEventRow()
        }
        .listStyle(.insetGrouped)
        .redacted(reason: .placeholder)
    }

    private func reload() async {
        guard let month = birthdateStore.month, let day = birthdateStore.day else { return }
        await viewModel.load(month: month, day: day)
    }
}

struct SelectedEventRow: View {
    let item: OnThisDayItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.title2)
                .foregroundStyle(BirthmateTheme.accent)

            VStack(alignment: .leading, spacing: 4) {
                if let year = item.eventYear {
                    Text(String(year))
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(BirthmateTheme.accent)
                }
                Text(item.displayText)
                    .font(.body.weight(.medium))
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

struct EventRow: View {
    let item: OnThisDayItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let year = item.eventYear {
                Text(String(year))
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(BirthmateTheme.accent)
                    .frame(width: 44, alignment: .leading)
            }

            Text(item.displayText)
                .font(.body)
                .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

struct EventDetailView: View {
    let item: OnThisDayItem
    let dateLabel: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PersonHeroImageView(
                    urlString: item.primaryPage?.thumbnail?.source,
                    wikiTitle: item.primaryPage?.title
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(.horizontal)

                if let year = item.eventYear {
                    Text(String(year))
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(BirthmateTheme.accent)
                }

                Text(item.displayText)
                    .font(.title3.weight(.semibold))
                    .fixedSize(horizontal: false, vertical: true)

                if let extract = item.primaryPage?.extract, !extract.isEmpty {
                    Text(WikiFormatting.plainText(from: extract))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }

                ShareLink(item: WikiFormatting.shareText(for: item, dateLabel: dateLabel, isBirth: false)) {
                    Label("Share this event", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.medium))
                }

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
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    OnThisDayView().environmentObject(BirthdateStore())
}
