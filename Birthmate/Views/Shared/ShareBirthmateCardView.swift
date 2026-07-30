import SwiftUI

struct ShareBirthmateCardView: View {
    let personName: String
    let dateLabel: String
    let snippet: String

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                AppLogoView(size: 44, cornerRadius: 10, showsShadow: false)
                Text("Birthmate")
                    .font(.headline)
                Spacer()
            }

            Text("I share \(dateLabel) with")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(personName)
                .font(.title.bold())
                .foregroundStyle(BirthmateTheme.accent)

            if !snippet.isEmpty {
                Text(snippet)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(4)
            }

            Text("Discover yours at Birthmate")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 320)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 16, y: 8)
        )
    }
}

enum ShareCardRenderer {
    @MainActor
    static func image(for item: OnThisDayItem, dateLabel: String) -> UIImage? {
        let snippet: String
        if let extract = item.primaryPage?.extract, !extract.isEmpty {
            snippet = WikiFormatting.plainText(from: extract)
        } else {
            snippet = WikiFormatting.plainText(from: item.text)
        }

        let view = ShareBirthmateCardView(
            personName: item.displayName,
            dateLabel: dateLabel,
            snippet: snippet
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
    let item: OnThisDayItem
    let dateLabel: String

    var body: some View {
        if let image = ShareCardRenderer.image(for: item, dateLabel: dateLabel),
           let url = ShareCardRenderer.temporaryFileURL(for: image) {
            ShareLink(
                item: url,
                preview: SharePreview("My Birthmate", image: Image(uiImage: image))
            ) {
                Label("Share card", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
            }
        } else {
            ShareLink(item: WikiFormatting.shareText(for: item, dateLabel: dateLabel, isBirth: true)) {
                Label("Share your Birthmate", systemImage: "square.and.arrow.up")
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}
