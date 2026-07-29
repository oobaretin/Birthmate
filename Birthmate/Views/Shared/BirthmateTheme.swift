import SwiftUI

enum BirthmateTheme {
    static let accent = Color.pink

    static var onboardingGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.pink.opacity(0.15),
                Color.orange.opacity(0.08),
                Color(.systemBackground)
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
}
