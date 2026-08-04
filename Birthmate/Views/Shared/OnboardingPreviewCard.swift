import SwiftUI

struct OnboardingPreviewCard: View {
    let dateLabel: String
    let sampleName: String?
    let birthCount: Int?
    let sampleEvent: String?
    let isLoading: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Preview for \(dateLabel)", systemImage: "sparkles")
                .font(.caption.weight(.semibold))
                .foregroundStyle(BirthmateTheme.accent)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading a glimpse of your day…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let birthCount, birthCount > 0, let sampleName {
                Text("Includes **\(sampleName)** and **\(birthCount.formatted())** others born on this day.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let sampleEvent {
                    HStack(alignment: .top, spacing: 8) {
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
            } else {
                Text("Pick a date to see famous birthmates and history from Wikipedia.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(BirthmateTheme.cream.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
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
