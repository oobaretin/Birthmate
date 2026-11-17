import SwiftUI

struct ShareBirthmateCardView: View {
    let personName: String
    let dateLabel: String
    let snippet: String
    var portrait: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AppLogoView(size: 40, cornerRadius: 9, showsShadow: false)
                Text("Birthmate")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .top, spacing: 14) {
                if let portrait {
                    Image(uiImage: portrait)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(BirthmateTheme.accent.opacity(0.2), lineWidth: 1)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("I share \(dateLabel) with")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(personName)
                        .font(.title3.bold())
                        .foregroundStyle(BirthmateTheme.accent)
                        .lineLimit(3)

                    if !snippet.isEmpty {
                        Text(snippet)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
            }

            Text("Discover your birthmates in Birthmate")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(20)
        .frame(width: 320)
        .background {
            RoundedRectangle(cornerRadius: BirthmateTheme.radiusHero, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            BirthmateTheme.cream,
                            Color(.systemBackground)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: BirthmateTheme.radiusHero, style: .continuous)
                        .strokeBorder(BirthmateTheme.accent.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.1), radius: 14, y: 6)
        }
    }
}

enum ShareCardRenderer {
    @MainActor
    static func image(for item: OnThisDayItem, dateLabel: String, portrait: UIImage? = nil) -> UIImage? {
        let snippet: String
        if let extract = item.primaryPage?.extract, !extract.isEmpty {
            snippet = WikiFormatting.plainText(from: extract)
        } else {
            snippet = WikiFormatting.plainText(from: item.text)
        }

        let view = ShareBirthmateCardView(
            personName: item.displayName,
            dateLabel: dateLabel,
            snippet: snippet,
            portrait: portrait
        )

        let renderer = ImageRenderer(content: view)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    static func temporaryFileURL(for image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("birthmate-share-\(UUID().uuidString).png")
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

struct ShareBirthmateCardLink: View {
    enum Style {
        case compact
        case prominent
    }

    let item: OnThisDayItem
    let dateLabel: String
    var style: Style = .compact

    @State private var portrait: UIImage?

    private var loadKey: String {
        "\(item.id)|\(item.primaryPage?.thumbnail?.source ?? "")|\(item.primaryPage?.title ?? "")"
    }

    var body: some View {
        shareControl
            .task(id: loadKey) {
                portrait = await WikiPersonImageService.shared.image(
                    primaryURL: item.primaryPage?.thumbnail?.source,
                    wikiTitle: item.primaryPage?.title,
                    width: 400
                )
            }
    }

    @ViewBuilder
    private var shareControl: some View {
        if let cardImage = ShareCardRenderer.image(for: item, dateLabel: dateLabel, portrait: portrait),
           let url = ShareCardRenderer.temporaryFileURL(for: cardImage) {
            ShareLink(
                item: url,
                preview: SharePreview("My Birthmate", image: Image(uiImage: cardImage))
            ) {
                shareLabel
            }
        } else {
            ShareLink(item: WikiFormatting.shareText(for: item, dateLabel: dateLabel, isBirth: true)) {
                shareLabel
            }
        }
    }

    @ViewBuilder
    private var shareLabel: some View {
        switch style {
        case .compact:
            Label("Share card", systemImage: "square.and.arrow.up")
                .font(.subheadline.weight(.medium))
        case .prominent:
            Label("Share birthmate card", systemImage: "square.and.arrow.up")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
    }
}