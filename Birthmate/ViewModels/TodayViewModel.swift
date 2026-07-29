import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var featuredPerson: OnThisDayItem?
    @Published var featuredEvent: OnThisDayItem?
    @Published var birthCount = 0
    @Published var eventCount = 0
    @Published var highlightCount = 0
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    private var cachedBirths: [OnThisDayItem] = []
    private var cachedHighlights: [OnThisDayItem] = []
    private var cachedEvents: [OnThisDayItem] = []
    private var loadedMonth: Int?
    private var loadedDay: Int?

    func load(month: Int, day: Int, forceRefresh: Bool = false) async {
        errorMessage = nil

        let isInitialLoad = featuredPerson == nil && featuredEvent == nil
        isLoading = isInitialLoad
        isRefreshing = !isInitialLoad && forceRefresh
        defer {
            isLoading = false
            isRefreshing = false
        }

        loadedMonth = month
        loadedDay = day

        var births: [OnThisDayItem] = cachedBirths
        var events: [OnThisDayItem] = cachedEvents
        var highlights: [OnThisDayItem] = cachedHighlights
        var updatedAt: Date?

        if !forceRefresh,
           let cachedBirths = WikidataService.shared.cachedBirths(month: month, day: day),
           !cachedBirths.items.isEmpty {
            births = cachedBirths.items
            updatedAt = cachedBirths.fetchedAt
            storeAndApply(births: births, events: events, highlights: highlights, month: month, day: day)
        }

        if !forceRefresh,
           let cachedEvents = APIService.shared.cachedEntry(type: .events, month: month, day: day),
           let cachedSelected = APIService.shared.cachedEntry(type: .selected, month: month, day: day) {
            events = cachedEvents.items.filter(\.hasValidEventYear)
            highlights = cachedSelected.items.filter(\.hasValidEventYear)
            updatedAt = max(updatedAt ?? .distantPast, cachedEvents.fetchedAt, cachedSelected.fetchedAt)
            storeAndApply(births: births, events: events, highlights: highlights, month: month, day: day)
        }

        do {
            async let birthsTask = loadBirths(month: month, day: day, forceRefresh: forceRefresh)
            async let eventsTask = APIService.shared.fetch(
                type: .events,
                month: month,
                day: day,
                forceRefresh: forceRefresh
            )
            async let selectedTask = APIService.shared.fetch(
                type: .selected,
                month: month,
                day: day,
                forceRefresh: forceRefresh
            )

            let (freshBirths, freshEvents, freshSelected) = try await (birthsTask, eventsTask, selectedTask)
            births = freshBirths
            events = freshEvents.items.filter(\.hasValidEventYear)
            highlights = freshSelected.items.filter(\.hasValidEventYear)
            updatedAt = max(freshEvents.fetchedAt, freshSelected.fetchedAt)
            storeAndApply(births: births, events: events, highlights: highlights, month: month, day: day)
            lastUpdated = updatedAt ?? Date()
        } catch {
            if featuredPerson == nil && featuredEvent == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    func showAnotherFeaturedPerson() {
        guard loadedMonth != nil, loadedDay != nil else { return }
        featuredPerson = randomPerson(excluding: featuredPerson?.id)
        syncWidgetSnapshot()
    }

    func showAnotherFeaturedEvent() {
        guard loadedMonth != nil, loadedDay != nil else { return }
        featuredEvent = randomEvent(excluding: featuredEvent?.id)
    }

    private func loadBirths(month: Int, day: Int, forceRefresh: Bool) async throws -> [OnThisDayItem] {
        do {
            let fresh = try await WikidataService.shared.fetchBirths(
                month: month,
                day: day,
                forceRefresh: forceRefresh,
                onPartialUpdate: nil
            )
            return fresh.items
        } catch {
            let fallback = try await APIService.shared.fetch(
                type: .births,
                month: month,
                day: day,
                forceRefresh: forceRefresh
            )
            return fallback.items
        }
    }

    private func storeAndApply(
        births: [OnThisDayItem],
        events: [OnThisDayItem],
        highlights: [OnThisDayItem],
        month: Int,
        day: Int
    ) {
        cachedBirths = births
        cachedEvents = events
        cachedHighlights = highlights
        loadedMonth = month
        loadedDay = day

        birthCount = births.count
        let selectedIDs = Set(highlights.map(\.id))
        eventCount = highlights.count + events.filter { !selectedIDs.contains($0.id) }.count
        highlightCount = highlights.count

        repickFeatured()
        syncWidgetSnapshot()
    }

    private func repickFeatured() {
        featuredPerson = randomPerson(excluding: nil)
        featuredEvent = randomEvent(excluding: nil)
    }

    private func randomPerson(excluding excludedID: String?) -> OnThisDayItem? {
        let pool = cachedBirths.filter { $0.id != excludedID }
        guard !pool.isEmpty else { return cachedBirths.randomElement() }
        return pool.randomElement()
    }

    private func randomEvent(excluding excludedID: String?) -> OnThisDayItem? {
        let combined = eventPool()
        let pool = combined.filter { $0.id != excludedID }
        guard !pool.isEmpty else { return combined.randomElement() }
        return pool.randomElement()
    }

    private func eventPool() -> [OnThisDayItem] {
        if cachedHighlights.isEmpty { return cachedEvents }
        let highlightIDs = Set(cachedHighlights.map(\.id))
        return cachedHighlights + cachedEvents.filter { !highlightIDs.contains($0.id) }
    }

    private func syncWidgetSnapshot() {
        guard let month = loadedMonth, let day = loadedDay else { return }
        WidgetDataStore.update(
            month: month,
            day: day,
            totalCount: birthCount,
            featuredName: featuredPerson?.displayName,
            featuredYear: featuredPerson?.birthYear
        )
    }
}
