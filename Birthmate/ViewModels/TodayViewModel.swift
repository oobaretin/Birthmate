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
    private var cachedDeaths: [OnThisDayItem] = []
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

        if !forceRefresh, let cached = await cachedPayload(month: month, day: day) {
            storeAndApply(
                births: cached.births,
                events: cached.events,
                highlights: cached.highlights,
                deaths: cached.deaths,
                month: month,
                day: day,
                shouldRepickFeatured: isInitialLoad
            )
            if let fetchedAt = cached.fetchedAt {
                lastUpdated = fetchedAt
            }
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
            async let deathsTask = APIService.shared.fetch(
                type: .deaths,
                month: month,
                day: day,
                forceRefresh: forceRefresh
            )

            let (freshBirths, freshEvents, freshSelected, freshDeaths) = try await (
                birthsTask,
                eventsTask,
                selectedTask,
                deathsTask
            )

            storeAndApply(
                births: freshBirths,
                events: freshEvents.items.filter(\.hasValidEventYear),
                highlights: freshSelected.items.filter(\.hasValidEventYear),
                deaths: freshDeaths.items.filter(\.hasValidEventYear),
                month: month,
                day: day,
                shouldRepickFeatured: isInitialLoad
            )
            lastUpdated = max(
                freshEvents.fetchedAt,
                freshSelected.fetchedAt,
                freshDeaths.fetchedAt
            )
        } catch {
            if isInitialLoad, featuredPerson == nil, featuredEvent == nil, cachedBirths.isEmpty {
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

    private struct CachedPayload {
        let births: [OnThisDayItem]
        let events: [OnThisDayItem]
        let highlights: [OnThisDayItem]
        let deaths: [OnThisDayItem]
        let fetchedAt: Date?
    }

    private func cachedPayload(month: Int, day: Int) async -> CachedPayload? {
        var births: [OnThisDayItem] = []
        var events: [OnThisDayItem] = []
        var highlights: [OnThisDayItem] = []
        var deaths: [OnThisDayItem] = []
        var fetchedAt: Date?

        if let wikidata = WikidataService.shared.cachedBirths(month: month, day: day),
           wikidata.isComplete,
           !wikidata.items.isEmpty {
            let wikiBirths = try? await APIService.shared.fetch(
                type: .births,
                month: month,
                day: day,
                forceRefresh: false
            )
            births = OnThisDayMerger.merge(wikidata.items, wikiBirths?.items ?? [])
            fetchedAt = wikidata.fetchedAt
        }

        if let cachedEvents = APIService.shared.cachedEntry(type: .events, month: month, day: day) {
            events = cachedEvents.items.filter(\.hasValidEventYear)
            fetchedAt = max(fetchedAt ?? .distantPast, cachedEvents.fetchedAt)
        }

        if let cachedSelected = APIService.shared.cachedEntry(type: .selected, month: month, day: day) {
            highlights = cachedSelected.items.filter(\.hasValidEventYear)
            fetchedAt = max(fetchedAt ?? .distantPast, cachedSelected.fetchedAt)
        }

        if let cachedDeaths = APIService.shared.cachedEntry(type: .deaths, month: month, day: day) {
            deaths = cachedDeaths.items.filter(\.hasValidEventYear)
            fetchedAt = max(fetchedAt ?? .distantPast, cachedDeaths.fetchedAt)
        }

        guard !births.isEmpty || !events.isEmpty || !highlights.isEmpty || !deaths.isEmpty else {
            return nil
        }

        return CachedPayload(
            births: births,
            events: events,
            highlights: highlights,
            deaths: deaths,
            fetchedAt: fetchedAt
        )
    }

    private func loadBirths(month: Int, day: Int, forceRefresh: Bool) async throws -> [OnThisDayItem] {
        async let wikiTask = APIService.shared.fetch(
            type: .births,
            month: month,
            day: day,
            forceRefresh: forceRefresh
        )

        var wikidataItems: [OnThisDayItem] = []
        do {
            let fresh = try await WikidataService.shared.fetchBirths(
                month: month,
                day: day,
                forceRefresh: forceRefresh,
                onPartialUpdate: nil
            )
            wikidataItems = fresh.items
        } catch {
            if let cached = WikidataService.shared.cachedBirths(month: month, day: day),
               cached.isComplete,
               !cached.items.isEmpty {
                wikidataItems = cached.items
            }
        }

        let wikiItems = (try? await wikiTask)?.items ?? []
        let merged = OnThisDayMerger.merge(wikiItems, wikidataItems)
        if !merged.isEmpty {
            return merged
        }

        if !wikiItems.isEmpty {
            return wikiItems
        }

        let fallback = try await APIService.shared.fetch(
            type: .births,
            month: month,
            day: day,
            forceRefresh: forceRefresh
        )
        return fallback.items
    }

    private func storeAndApply(
        births: [OnThisDayItem],
        events: [OnThisDayItem],
        highlights: [OnThisDayItem],
        deaths: [OnThisDayItem],
        month: Int,
        day: Int,
        shouldRepickFeatured: Bool
    ) {
        cachedBirths = OnThisDayMerger.merge(cachedBirths, births)
        cachedEvents = events
        cachedHighlights = highlights
        cachedDeaths = deaths
        loadedMonth = month
        loadedDay = day

        birthCount = cachedBirths.count
        highlightCount = highlights.count
        eventCount = uniqueHistoryCount(highlights: highlights, events: events, deaths: deaths)

        if shouldRepickFeatured {
            repickFeaturedItems()
        }
        syncWidgetSnapshot()
    }

    private func uniqueHistoryCount(
        highlights: [OnThisDayItem],
        events: [OnThisDayItem],
        deaths: [OnThisDayItem]
    ) -> Int {
        var seen = Set<String>()
        var count = 0
        for item in highlights + events + deaths {
            if seen.insert(item.id).inserted {
                count += 1
            }
        }
        return count
    }

    private func repickFeaturedItems() {
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

    func isDeath(_ item: OnThisDayItem) -> Bool {
        cachedDeaths.contains { $0.id == item.id }
    }

    private func eventPool() -> [OnThisDayItem] {
        let highlightIDs = Set(cachedHighlights.map(\.id))
        let events = cachedEvents.filter { !highlightIDs.contains($0.id) }
        let knownIDs = highlightIDs.union(events.map(\.id))
        let deaths = cachedDeaths.filter { !knownIDs.contains($0.id) }
        if cachedHighlights.isEmpty {
            return cachedEvents + deaths
        }
        return cachedHighlights + events + deaths
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
