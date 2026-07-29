import Foundation

@MainActor
final class OnThisDayViewModel: ObservableObject {
    @Published var allEvents: [OnThisDayItem] = []
    @Published var allSelected: [OnThisDayItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?
    @Published var filter: EventFilter = .all {
        didSet { /* sections computed on read */ }
    }

    var totalCount: Int {
        let selectedIDs = Set(allSelected.map(\.id))
        return allSelected.count + allEvents.filter { !selectedIDs.contains($0.id) }.count
    }

    var highlightCount: Int { allSelected.count }

    func load(month: Int, day: Int) async {
        errorMessage = nil

        if let cachedEvents = APIService.shared.cachedEntry(type: .events, month: month, day: day),
           let cachedSelected = APIService.shared.cachedEntry(type: .selected, month: month, day: day) {
            apply(events: cachedEvents.items, selected: cachedSelected.items)
            lastUpdated = max(cachedEvents.fetchedAt, cachedSelected.fetchedAt)
        }

        isLoading = allEvents.isEmpty && allSelected.isEmpty
        do {
            async let eventsTask = APIService.shared.fetch(type: .events, month: month, day: day, forceRefresh: true)
            async let selectedTask = APIService.shared.fetch(type: .selected, month: month, day: day, forceRefresh: true)
            let (freshEvents, freshSelected) = try await (eventsTask, selectedTask)
            apply(events: freshEvents.items, selected: freshSelected.items)
            lastUpdated = max(freshEvents.fetchedAt, freshSelected.fetchedAt)
        } catch {
            if allEvents.isEmpty && allSelected.isEmpty {
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
            let items = filterItems(allEvents, matching: searchText)
            return FeedSectionBuilder.build(from: items) { $0.eventYear }.map {
                FeedSection(id: $0.id, title: $0.title, subtitle: "\($0.items.count) events", items: $0.items)
            }

        case .all:
            var sections: [FeedSection] = []
            let highlights = filterItems(allSelected, matching: searchText)
            if !highlights.isEmpty {
                sections.append(FeedSection(id: "highlights", title: "Highlights", subtitle: "\(highlights.count) featured events", items: highlights))
            }
            let selectedIDs = Set(allSelected.map(\.id))
            let events = filterItems(allEvents.filter { !selectedIDs.contains($0.id) }, matching: searchText)
            sections.append(contentsOf: FeedSectionBuilder.build(from: events) { $0.eventYear }.map {
                FeedSection(id: $0.id, title: $0.title, subtitle: "\($0.items.count) events", items: $0.items)
            })
            return sections
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

    private func apply(events: [OnThisDayItem], selected: [OnThisDayItem]) {
        allEvents = events.filter(\.hasValidEventYear).sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
        allSelected = selected.filter(\.hasValidEventYear).sorted { ($0.eventYear ?? 0) > ($1.eventYear ?? 0) }
    }
}
