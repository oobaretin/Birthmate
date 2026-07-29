import Foundation

enum BirthmateSecrets {
    static var supabaseURL: URL? {
        string(for: "SUPABASE_URL").flatMap(URL.init(string:))
    }

    static var supabaseAnonKey: String? {
        string(for: "SUPABASE_ANON_KEY")
    }

    static var isCommunityConfigured: Bool {
        supabaseURL != nil && supabaseAnonKey != nil
    }

    private static func string(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.hasPrefix("YOUR_") else { return nil }
        return trimmed
    }
}
