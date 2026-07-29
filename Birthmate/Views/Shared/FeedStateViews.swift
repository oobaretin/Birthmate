import SwiftUI

enum WikiImageLoader {
    static func load(from urlString: String?) async -> UIImage? {
        guard let resolved = WikiImageURL.resolved(urlString),
              let url = WikiImageURL.url(from: resolved) else { return nil }

        var request = URLRequest(url: url)
        request.setValue("Birthmate/1.0 (iOS app; contact: github.com/oobaretin/Birthmate)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200...299).contains(http.statusCode),
                  let image = UIImage(data: data) else { return nil }
            return image
        } catch {
            return nil
        }
    }
}

struct PersonThumbnailView: View {
    let urlString: String?
    var wikiTitle: String?
    var size: CGFloat = 56

    @State private var fallbackImage: UIImage?

    private var resolvedURL: URL? {
        guard let resolved = WikiImageURL.resolved(urlString) else { return nil }
        return WikiImageURL.url(from: resolved)
    }

    var body: some View {
        Group {
            if let fallbackImage {
                imageView(Image(uiImage: fallbackImage))
            } else if let resolvedURL {
                AsyncImage(url: resolvedURL) { phase in
                    switch phase {
                    case .success(let image):
                        imageView(image)
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                    @unknown default:
                        placeholder
                    }
                }
            } else {
                placeholder
            }
        }
        .onAppear {
            guard resolvedURL == nil, fallbackImage == nil, let wikiTitle else { return }
            Task { await loadFallback(title: wikiTitle) }
        }
    }

    private func imageView(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipShape(Circle())
    }

    private var placeholder: some View {
        Circle()
            .fill(BirthmateTheme.accent.opacity(0.15))
            .overlay(
                Image(systemName: "person.fill")
                    .foregroundStyle(BirthmateTheme.accent)
            )
            .frame(width: size, height: size)
    }

    private func loadFallback(title: String) async {
        let item = OnThisDayItem(
            text: title,
            year: nil,
            pages: [WikiPage(
                title: title,
                displayTitle: title,
                extract: nil,
                thumbnail: nil,
                originalImage: nil,
                contentUrls: nil
            )]
        )
        guard let fallbackURL = await WikipediaSummaryService.shared.fetchThumbnailURL(for: item),
              let loaded = await WikiImageLoader.load(from: fallbackURL) else { return }
        await MainActor.run { fallbackImage = loaded }
    }
}

struct PersonHeroImageView: View {
    let urlString: String?
    var wikiTitle: String?

    @State private var fallbackImage: UIImage?

    private var resolvedURL: URL? {
        if let wide = WikiImageURL.resolved(urlString, width: 800),
           let url = WikiImageURL.url(from: wide) {
            return url
        }
        guard let resolved = WikiImageURL.resolved(urlString) else { return nil }
        return WikiImageURL.url(from: resolved)
    }

    var body: some View {
        Group {
            if let fallbackImage {
                Image(uiImage: fallbackImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()
            } else if let resolvedURL {
                AsyncImage(url: resolvedURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                            .clipped()
                    default:
                        heroPlaceholder
                    }
                }
            } else {
                heroPlaceholder
            }
        }
        .onAppear {
            guard resolvedURL == nil, fallbackImage == nil, let wikiTitle else { return }
            Task { await loadFallback(title: wikiTitle) }
        }
    }

    private var heroPlaceholder: some View {
        Rectangle()
            .fill(BirthmateTheme.accent.opacity(0.12))
            .frame(height: 180)
            .overlay(
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(BirthmateTheme.accent.opacity(0.5))
            )
    }

    private func loadFallback(title: String) async {
        let item = OnThisDayItem(
            text: title,
            year: nil,
            pages: [WikiPage(
                title: title,
                displayTitle: title,
                extract: nil,
                thumbnail: nil,
                originalImage: nil,
                contentUrls: nil
            )]
        )
        guard let fallbackURL = await WikipediaSummaryService.shared.fetchThumbnailURL(for: item),
              let loaded = await WikiImageLoader.load(from: fallbackURL) else { return }
        await MainActor.run { fallbackImage = loaded }
    }
}

struct SkeletonPersonRow: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(.systemGray5))
                .frame(width: 50, height: 50)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray5))
                    .frame(height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 120, height: 12)
            }
        }
        .padding(.vertical, 4)
        .redacted(reason: .placeholder)
    }
}

struct SkeletonEventRow: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 48, height: 12)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(height: 14)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 220, height: 14)
        }
        .padding(.vertical, 4)
        .redacted(reason: .placeholder)
    }
}

struct FeedErrorView: View {
    let message: String
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn't Load", systemImage: "wifi.slash")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await retry() }
            }
            .buttonStyle(.borderedProminent)
            .tint(BirthmateTheme.accent)
        }
    }
}

struct FeedEmptyView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: systemImage, description: Text(message))
    }
}

struct StatBadge: View {
    let value: Int
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(BirthmateTheme.accent)
            Text("\(value)")
                .font(.headline.monospacedDigit())
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
