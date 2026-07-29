import Foundation

@MainActor
final class TodayViewModel: ObservableObject {
    @Published var featuredPerson: OnThisDayItem?
    @Published var featuredEvent: OnThisDayItem?
    @Published var birthCount = 0
    @Published var eventCount = 0
    @Published var highlightCount = 0
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastUpdated: Date?

    func load(month: Int, day: Int) async {
        errorMessage = nil
        isLoading = featuredPerson == nil && featuredEvent == nil

        var births: [OnThisDayItem] = []
        var events: [OnThisDayItem] = []
        var highlights: [OnThisDayItem] = []
        var updatedAt: Date?

        if let cachedBirths = WikidataService.shared.cachedBirths(month: month, day: day),
           !cachedBirths.items.isEmpty {
            births = cachedBirths.items
            updatedAt = cachedBirths.fetchedAt
            applySummary(births: births, events: events, highlights: highlights, month: month, day: day)
        }

        if let cachedEvents = APIService.shared.cachedEntry(type: .events, month: month, day: day),
           let cachedSelected = APIService.shared.cachedEntry(type: .selected, month: month, day: day) {
            events = cachedEvents.items.filter(\.hasValidEventYear)
            highlights = cachedSelected.items.filter(\.hasValidEventYear)
            updatedAt = max(updatedAt ?? .distantPast, cachedEvents.fetchedAt, cachedSelected.fetchedAt)
            applySummary(births: births, events: events, highlights: highlights, month: month, day: day)
        }

        do {
            async let birthsTask = loadBirths(month: month, day: day)
            async let eventsTask = APIService.shared.fetch(type: .events, month: month, day: day, forceRefresh: false)
            async let selectedTask = APIService.shared.fetch(type: .selected, month: month, day: day, forceRefresh: false)

            let (freshBirths, freshEvents, freshSelected) = try await (birthsTask, eventsTask, selectedTask)
            births = freshBirths
            events = freshEvents.items.filter(\.hasValidEventYear)
            highlights = freshSelected.items.filter(\.hasValidEventYear)
            updatedAt = max(freshEvents.fetchedAt, freshSelected.fetchedAt)
            applySummary(births: births, events: events, highlights: highlights, month: month, day: day)
            lastUpdated = updatedAt
        } catch {
            if featuredPerson == nil && featuredEvent == nil {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    private func loadBirths(month: Int, day: Int) async throws -> [OnThisDayItem] {
        do {
            let fresh = try await WikidataService.shared.fetchBirths(
                month: month,
                day: day,
                forceRefresh: false,
                onPartialUpdate: nil
            )
            return fresh.items
        } catch {
            let fallback = try await APIService.shared.fetch(type: .births, month: month, day: day, forceRefresh: false)
            return fallback.items
        }
    }

    private func applySummary(
        births: [OnThisDayItem],
        events: [OnThisDayItem],
        highlights: [OnThisDayItem],
        month: Int,
        day: Int
    ) {
        birthCount = births.count
        let selectedIDs = Set(highlights.map(\.id))
        eventCount = highlights.count + events.filter { !selectedIDs.contains($0.id) }.count
        highlightCount = highlights.count

        let seed = month * 100 + day
        featuredPerson = pickFeaturedPerson(from: births, seed: seed)
        featuredEvent = pickFeaturedEvent(highlights: highlights, events: events, seed: seed + 17)
    }

    private func pickFeaturedPerson(from items: [OnThisDayItem], seed: Int) -> OnThisDayItem? {
        let ranked = items
            .map { ($0, personScore($0)) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)

        guard !ranked.isEmpty else { return nil }
        return ranked[seed % min(5, ranked.count)]
    }

    private func pickFeaturedEvent(
        highlights: [OnThisDayItem],
        events: [OnThisDayItem],
        seed: Int
    ) -> OnThisDayItem? {
        let pool = highlights.isEmpty ? events : highlights
        let ranked = pool
            .map { ($0, eventScore($0)) }
            .sorted { $0.1 > $1.1 }
            .map(\.0)

        guard !ranked.isEmpty else { return nil }
        return ranked[seed % min(5, ranked.count)]
    }

    private func personScore(_ item: OnThisDayItem) -> Int {
        var score = 0
        if item.primaryPage?.thumbnail?.source != nil { score += 10 }
        if item.primaryPage?.extract?.isEmpty == false { score += 5 }
        if item.isLiving { score += 3 }
        if let year = item.birthYear, year >= Calendar.current.component(.year, from: Date()) - 60 {
            score += 2
        }
        return score
    }

    private func eventScore(_ item: OnThisDayItem) -> Int {
        var score = 0
        if item.primaryPage?.thumbnail?.source != nil { score += 5 }
        if item.primaryPage?.extract?.isEmpty == false { score += 3 }
        if let year = item.eventYear { score += min(4, year / 500) }
        return score
    }
}
