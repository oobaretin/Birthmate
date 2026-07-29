import Foundation

@MainActor
final class HomeBirthsViewModel: ObservableObject {
    @Published var allItems: [OnThisDayItem] = []
    @Published var sections: [BirthSection] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var filter: BirthFilter = .all {
        didSet { rebuildSections() }
    }

    var livingCount: Int { allItems.filter(\.isLiving).count }
    var totalCount: Int { allItems.count }

    private var loadedMonth: Int?
    private var loadedDay: Int?

    func load(month: Int, day: Int, forceRefresh: Bool = false) async {
        errorMessage = nil
        loadedMonth = month
        loadedDay = day

        if !forceRefresh,
           let cached = WikidataService.shared.cachedBirths(month: month, day: day),
           cached.isComplete,
           !cached.items.isEmpty {
            let wikiItems = await fetchWikipediaBirths(month: month, day: day, forceRefresh: false) ?? []
            apply(OnThisDayMerger.merge(cached.items, wikiItems))
            lastUpdated = cached.fetchedAt
            return
        }

        isLoading = allItems.isEmpty
        isLoadingMore = false

        async let wikiItemsTask = fetchWikipediaBirths(month: month, day: day, forceRefresh: forceRefresh)
        async let wikidataItemsTask = fetchWikidataBirths(month: month, day: day, forceRefresh: forceRefresh)

        let wikiItems = await wikiItemsTask ?? []
        if allItems.isEmpty, !wikiItems.isEmpty {
            apply(wikiItems)
            isLoading = false
            isLoadingMore = true
        }

        let wikidataItems = await wikidataItemsTask ?? []
        let merged = OnThisDayMerger.merge(wikiItems, wikidataItems)

        if !merged.isEmpty {
            apply(merged)
            lastUpdated = Date()
        } else if allItems.isEmpty {
            errorMessage = "Couldn't load birthmates. Check your connection and try again."
            sections = []
        }

        isLoading = false
        isLoadingMore = false
    }

    private func fetchWikipediaBirths(month: Int, day: Int, forceRefresh: Bool) async -> [OnThisDayItem]? {
        guard let entry = try? await APIService.shared.fetch(
            type: .births,
            month: month,
            day: day,
            forceRefresh: forceRefresh
        ) else { return nil }
        return entry.items
    }

    private func fetchWikidataBirths(month: Int, day: Int, forceRefresh: Bool) async -> [OnThisDayItem]? {
        guard let entry = try? await WikidataService.shared.fetchBirths(
            month: month,
            day: day,
            forceRefresh: forceRefresh,
            onPartialUpdate: nil
        ) else { return nil }
        return entry.items
    }

    func filteredItems(matching searchText: String, favoriteWikiTitles: Set<String> = []) -> [OnThisDayItem] {
        let base = itemsForFilter(filter, favoriteWikiTitles: favoriteWikiTitles)
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter { item in
            item.displayName.lowercased().contains(query)
                || item.text.lowercased().contains(query)
                || (item.primaryPage?.extract?.lowercased().contains(query) ?? false)
        }
    }

    func filteredSections(matching searchText: String, favoriteWikiTitles: Set<String> = []) -> [BirthSection] {
        FeedSectionBuilder.build(from: filteredItems(matching: searchText, favoriteWikiTitles: favoriteWikiTitles)) { $0.birthYear }
    }

    private func apply(_ fetched: [OnThisDayItem]) {
        allItems = fetched
            .filter(\.hasValidBirthYear)
            .sorted { ($0.birthYear ?? 0) > ($1.birthYear ?? 0) }
        rebuildSections()
        if let month = loadedMonth, let day = loadedDay {
            let featured = allItems.randomElement()
            WidgetDataStore.update(
                month: month,
                day: day,
                totalCount: allItems.count,
                featuredName: featured?.displayName,
                featuredYear: featured?.birthYear
            )
        }
    }

    private func itemsForFilter(_ filter: BirthFilter, favoriteWikiTitles: Set<String>) -> [OnThisDayItem] {
        switch filter {
        case .all: return allItems
        case .living: return allItems.filter(\.isLiving)
        case .historical: return allItems.filter { !$0.isLiving }
        case .favorites:
            return allItems.filter { item in
                guard let title = item.primaryPage?.title else { return false }
                return favoriteWikiTitles.contains(title)
            }
        }
    }

    private func rebuildSections() {
        let items = itemsForFilter(filter, favoriteWikiTitles: [])
        sections = FeedSectionBuilder.build(from: items) { $0.birthYear }.map { section in
            let livingInEra = section.items.filter(\.isLiving).count
            let subtitle = livingInEra > 0
                ? "\(section.items.count) people · \(livingInEra) living"
                : "\(section.items.count) people"
            return BirthSection(id: section.id, title: "Born \(section.title)", subtitle: subtitle, items: section.items)
        }
    }
}
