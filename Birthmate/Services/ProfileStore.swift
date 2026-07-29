import Foundation

@MainActor
final class ProfileStore: ObservableObject {
    @Published var displayName: String {
        didSet { persist() }
    }

    @Published var isDiscoverable: Bool {
        didSet { persist() }
    }

    @Published var discoverOthers: Bool {
        didSet { persist() }
    }

    @Published var famousTwinName: String? {
        didSet { persist() }
    }

    @Published var famousTwinWikiTitle: String? {
        didSet { persist() }
    }

    @Published var favoriteWikiTitles: Set<String> = [] {
        didSet { persistFavorites() }
    }

    let clientID: String

    private let displayNameKey = "birthmate_display_name"
    private let discoverableKey = "birthmate_is_discoverable"
    private let discoverOthersKey = "birthmate_discover_others"
    private let clientIDKey = "birthmate_client_id"
    private let famousTwinNameKey = "birthmate_famous_twin_name"
    private let famousTwinWikiTitleKey = "birthmate_famous_twin_wiki_title"
    private let favoritesKey = "birthmate_favorite_wiki_titles"

    var hasDisplayName: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canBrowseCommunity: Bool {
        discoverOthers
    }

    var requiresSignIn: Bool {
        BirthmateSecrets.isCommunityConfigured
    }

    init() {
        let defaults = UserDefaults.standard
        clientID = defaults.string(forKey: clientIDKey) ?? UUID().uuidString.lowercased()
        displayName = defaults.string(forKey: displayNameKey) ?? ""
        isDiscoverable = defaults.bool(forKey: discoverableKey)
        discoverOthers = defaults.object(forKey: discoverOthersKey) as? Bool ?? false
        famousTwinName = defaults.string(forKey: famousTwinNameKey)
        famousTwinWikiTitle = defaults.string(forKey: famousTwinWikiTitleKey)
        if let saved = defaults.array(forKey: favoritesKey) as? [String] {
            favoriteWikiTitles = Set(saved)
        }

        if defaults.string(forKey: clientIDKey) == nil {
            defaults.set(clientID, forKey: clientIDKey)
        }
    }

    func sanitizedDisplayName(fallback: String = "Birthmate") -> String {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : String(trimmed.prefix(32))
    }

    func setFamousTwin(from item: OnThisDayItem) {
        famousTwinName = item.displayName
        famousTwinWikiTitle = item.primaryPage?.title
    }

    func isFavorite(_ item: OnThisDayItem) -> Bool {
        guard let title = item.primaryPage?.title else { return false }
        return favoriteWikiTitles.contains(title)
    }

    func toggleFavorite(_ item: OnThisDayItem) {
        guard let title = item.primaryPage?.title else { return }
        if favoriteWikiTitles.contains(title) {
            favoriteWikiTitles.remove(title)
        } else {
            favoriteWikiTitles.insert(title)
        }
    }

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(displayName, forKey: displayNameKey)
        defaults.set(isDiscoverable, forKey: discoverableKey)
        defaults.set(discoverOthers, forKey: discoverOthersKey)
        defaults.set(famousTwinName, forKey: famousTwinNameKey)
        defaults.set(famousTwinWikiTitle, forKey: famousTwinWikiTitleKey)
    }

    private func persistFavorites() {
        UserDefaults.standard.set(Array(favoriteWikiTitles), forKey: favoritesKey)
    }
}
