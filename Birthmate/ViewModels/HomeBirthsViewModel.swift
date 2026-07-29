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

        if let cached = WikidataService.shared.cachedBirths(month: month, day: day),
           !cached.items.isEmpty {
            apply(cached.items)
            lastUpdated = cached.fetchedAt
        }

        isLoading = allItems.isEmpty
        isLoadingMore = !allItems.isEmpty

        do {
            let fresh = try await WikidataService.shared.fetchBirths(
                month: month,
                day: day,
                forceRefresh: forceRefresh
            ) { [weak self] partial in
                Task { @MainActor in
                    self?.apply(partial)
                    self?.isLoading = false
                    self?.isLoadingMore = true
                }
            }
            apply(fresh.items)
            lastUpdated = fresh.fetchedAt
        } catch {
            await loadWikipediaFallback(month: month, day: day)
        }

        isLoading = false
        isLoadingMore = false
    }

    private func loadWikipediaFallback(month: Int, day: Int) async {
        do {
            let fallback = try await APIService.shared.fetch(type: .births, month: month, day: day, forceRefresh: true)
            apply(fallback.items)
            lastUpdated = fallback.fetchedAt
        } catch {
            if allItems.isEmpty {
                errorMessage = error.localizedDescription
                sections = []
            }
        }
    }

    func filteredItems(matching searchText: String) -> [OnThisDayItem] {
        let base = itemsForFilter(filter)
        guard !searchText.isEmpty else { return base }
        let query = searchText.lowercased()
        return base.filter { item in
            item.displayName.lowercased().contains(query)
                || item.text.lowercased().contains(query)
                || (item.primaryPage?.extract?.lowercased().contains(query) ?? false)
        }
    }

    func filteredSections(matching searchText: String) -> [BirthSection] {
        FeedSectionBuilder.build(from: filteredItems(matching: searchText)) { $0.birthYear }
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

    private func itemsForFilter(_ filter: BirthFilter) -> [OnThisDayItem] {
        switch filter {
        case .all: return allItems
        case .living: return allItems.filter(\.isLiving)
        case .historical: return allItems.filter { !$0.isLiving }
        }
    }

    private func rebuildSections() {
        let items = itemsForFilter(filter)
        sections = FeedSectionBuilder.build(from: items) { $0.birthYear }.map { section in
            let livingInEra = section.items.filter(\.isLiving).count
            let subtitle = livingInEra > 0
                ? "\(section.items.count) people · \(livingInEra) living"
                : "\(section.items.count) people"
            return BirthSection(id: section.id, title: "Born \(section.title)", subtitle: subtitle, items: section.items)
        }
    }
}
