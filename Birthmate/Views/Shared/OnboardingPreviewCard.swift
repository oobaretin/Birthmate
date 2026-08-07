import SwiftUI

struct OnboardingPreviewCard: View {
    let dateLabel: String
    let sampleName: String?
    let sampleThumbURL: String?
    let sampleWikiTitle: String?
    let birthCount: Int?
    let sampleEvent: String?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Preview for \(dateLabel)", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BirthmateTheme.accent)

            if isLoading {
                HStack(spacing: 12) {
                    Circle()
                        .fill(BirthmateTheme.accent.opacity(0.12))
                        .frame(width: 52, height: 52)
                        .overlay(ProgressView())
                    Text("Loading a glimpse of your day…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let birthCount, birthCount > 0, let sampleName {
                HStack(alignment: .top, spacing: 12) {
                    PersonThumbnailView(
                        urlString: sampleThumbURL,
                        wikiTitle: sampleWikiTitle,
                        size: 52
                    )

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Includes **\(sampleName)** and **\(birthCount.formatted())** others born on this day.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        if let sampleEvent {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "clock.fill")
                                    .font(.caption)
                                    .foregroundStyle(BirthmateTheme.accent)
                                    .padding(.top, 2)
                                Text(sampleEvent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else {
                Text("Pick a date to see famous birthmates and history from Wikipedia.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(BirthmateTheme.cardPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BirthmateTheme.cream.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: BirthmateTheme.radiusCard, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: BirthmateTheme.radiusCard, style: .continuous)
                .strokeBorder(BirthmateTheme.accent.opacity(0.15), lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: sampleName)
    }
}

struct WikiAttributionFooter: View {
    var body: some View {
        Text("Data from Wikipedia and Wikidata.")
            .font(.caption2)
            .foregroundStyle(.tertiary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
    }
}
