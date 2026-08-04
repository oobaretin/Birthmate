import SwiftUI

enum BirthmateTheme {
    /// Warm coral-rose accent aligned with the logo.
    static let accent = Color(red: 0.82, green: 0.32, blue: 0.42)

    static let cream = Color(red: 0.98, green: 0.96, blue: 0.93)

    static var onboardingGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.18),
                Color.orange.opacity(0.08),
                cream.opacity(0.6),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var birthdayGradient: LinearGradient {
        LinearGradient(
            colors: [
                accent.opacity(0.25),
                Color.orange.opacity(0.15),
                accent.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func cardBackground() -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
    }

    static func heroCardBackground() -> some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(accent.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: accent.opacity(0.08), radius: 12, y: 4)
    }
}
