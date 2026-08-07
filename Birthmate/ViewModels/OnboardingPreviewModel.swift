import Foundation

@MainActor
final class OnboardingPreviewModel: ObservableObject {
    @Published var sampleName: String?
    @Published var sampleThumbURL: String?
    @Published var sampleWikiTitle: String?
    @Published var birthCount: Int?
    @Published var sampleEvent: String?
    @Published var isLoading = false

    private var loadTask: Task<Void, Never>?

    func load(month: Int, day: Int) {
        loadTask?.cancel()
        loadTask = Task {
            isLoading = true
            sampleName = nil
            sampleThumbURL = nil
            sampleWikiTitle = nil
            birthCount = nil
            sampleEvent = nil

            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }

            do {
                async let birthsTask = APIService.shared.fetch(type: .births, month: month, day: day)
                async let selectedTask = APIService.shared.fetch(type: .selected, month: month, day: day)
                let (births, selected) = try await (birthsTask, selectedTask)

                guard !Task.isCancelled else { return }

                birthCount = births.items.count
                if let first = births.items.first {
                    sampleName = first.displayName
                    sampleThumbURL = first.primaryPage?.thumbnail?.source
                    sampleWikiTitle = first.primaryPage?.title
                }
                if let event = selected.items.first {
                    let text = event.displayText
                    sampleEvent = text.count > 120 ? String(text.prefix(117)) + "…" : text
                }
            } catch {
                guard !Task.isCancelled else { return }
            }

            isLoading = false
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
}
