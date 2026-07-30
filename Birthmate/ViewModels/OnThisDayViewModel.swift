import Foundation

@MainActor
final class OnThisDayViewModel: ObservableObject {
    @Published var allEvents: [OnThisDayItem] = []
    @Published var allSelected: [OnThisDayItem] = []
    @Published var allDeaths: [OnThisDayItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var filter: EventFilter = .all {
        didSet { /* sections computed on read */ }
    }

    var totalCount: Int {
        var seen = Set<String>()
        var count = 0
        for item in allSelected + allEvents + allDeaths {
            if seen.insert(item.id).inserted {
                count += 1
            }
        }
        return count
    }

    var highlightCount: Int { allSelected.count }

    func isDeath(_ item: OnThisDayItem) -> Bool {
        allDeaths.contains { $0.id == item.id }
    }

    func load(month: Int, day: Int) async {
        errorMessage = nil

        if let cachedEvents = APIService.shared.cachedEntry(type: .events, month: month, day: day),
           let cachedSelected = APIService.shared.cachedEntry(type: .selected, month: month, day: day),
           let cachedDeaths = APIService.shared.cachedEntry(type: .deaths, month: month, day: day) {
            apply(
                events: cachedEvents.items,
                selected: cachedSelected.items,
                deaths: cachedDeaths.items
            )
            lastUpdated = max(cachedEvents.fetchedAt, cachedSelected.fetchedAt, cachedDeaths.fetchedAt)
        }

        isLoading = allEvents.isEmpty && allSelected.isEmpty && allDeaths.isEmpty
        do {
            async let eventsTask = APIService.shared.fetch(type: .events, month: month, day: day, forceRefresh: true)
            async let selectedTask = APIService.shared.fetch(type: .selected, month: month, day: day, forceRefresh: true)
            async let deathsTask = APIService.shared.fetch(type: .deaths, month: month, day: day, forceRefresh: true)
            let (freshEvents, freshSelected, freshDeaths) = try await (eventsTask, selectedTask, deathsTask)
            apply(events: freshEvents.items, selected: freshSelected.items, deaths: freshDeaths.items)
            lastUpdated = max(freshEvents.fetchedAt, freshSelected.fetchedAt, freshDeaths.fetchedAt)
        } catch {
            if allEvents.isEmpty && allSelected.isEmpty && allDeaths.isEmpty {
                errorMessage = error.localizedDescription
            }
        }
        isLoading = false
    }

    func displaySections(matching searchText: String) -> [FeedSection] {
        switch filter {
        case .highlights:
            let items = filterItems(allSelected, matching: searchText)
            guard !items.isEmpty else { return [] }
            return [FeedSection(id: "highlights", title: "Highlights", subtitle: "\(items.count) featured events", items: items)]

        case .events:
            let items = filterItems(timelineItems(excludingHighlights: false), matching: searchText)
            return eraSections(from: items)

        case .all:
            var sections: [FeedSection] = []
            let highlights = filterItems(allSelected, matching: searchText)
            if !highlights.isEmpty {
                sections.append(FeedSection(id: "highlights", title: "Highlights", subtitle: "\(highlights.count) featured events", items: highlights))
            }

            let items = filterItems(timelineItems(excludingHighlights: true), matching: searchText)
            sections.append(contentsOf: eraSections(from: items))
            return sections
        }
    }

    private func timelineItems(excludingHighlights: Bool) -> [OnThisDayItem] {
        let highlightIDs = excludingHighlights ? Set(allSelected.map(\.id)) : []
        var seen = Set<String>()
        var items: [OnThisDayItem] = []

        for item in allEvents + allDeaths {
            guard !highlightIDs.contains(item.id), seen.insert(item.id).inserted else { continue }
            items.append(item)
        }

        return items.sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
    }

    private func eraSections(from items: [OnThisDayItem]) -> [FeedSection] {
        FeedSectionBuilder.build(from: items) { $0.eventYear }.map {
            FeedSection(id: $0.id, title: $0.title, subtitle: "\($0.items.count) events", items: $0.items)
        }
    }

    private func filterItems(_ items: [OnThisDayItem], matching searchText: String) -> [OnThisDayItem] {
        guard !searchText.isEmpty else { return items }
        let query = searchText.lowercased()
        return items.filter { item in
            item.displayText.lowercased().contains(query)
                || (item.primaryPage?.extract?.lowercased().contains(query) ?? false)
        }
    }

    private func apply(events: [OnThisDayItem], selected: [OnThisDayItem], deaths: [OnThisDayItem]) {
        allEvents = events.filter(\.hasValidEventYear).sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
        allSelected = selected.filter(\.hasValidEventYear).sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
        allDeaths = deaths.filter(\.hasValidEventYear).sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
    }
}
