import SwiftUI

enum WikiImageLoader {
    static func load(from urlString: String?, width: Int = 330) async -> UIImage? {
        guard let resolved = WikiImageURL.resolved(urlString, width: width),
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

actor WikiPersonImageService {
    static let shared = WikiPersonImageService()

    private var cache: [String: UIImage] = [:]

    func image(primaryURL: String?, wikiTitle: String?, width: Int = 330) async -> UIImage? {
        let cacheKey = "\(primaryURL ?? "")|\(wikiTitle ?? "")|\(width)"
        if let cached = cache[cacheKey] { return cached }

        if let primaryURL,
           let loaded = await WikiImageLoader.load(from: primaryURL, width: width) {
            cache[cacheKey] = loaded
            return loaded
        }

        if let wikiTitle,
           let thumbURL = await WikipediaSummaryService.shared.fetchThumbnailURL(title: wikiTitle),
           let loaded = await WikiImageLoader.load(from: thumbURL, width: width) {
            cache[cacheKey] = loaded
            return loaded
        }

        return nil
    }
}

struct PersonThumbnailView: View {
    let urlString: String?
    var wikiTitle: String?
    var size: CGFloat = 56

    @State private var image: UIImage?

    private var loadKey: String {
        "\(urlString ?? "")|\(wikiTitle ?? "")"
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                placeholder
            }
        }
        .task(id: loadKey) {
            await loadImage()
        }
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

    private func loadImage() async {
        image = nil
        let loaded = await WikiPersonImageService.shared.image(
            primaryURL: urlString,
            wikiTitle: wikiTitle,
            width: 330
        )
        await MainActor.run { image = loaded }
    }
}

struct PersonHeroImageView: View {
    let urlString: String?
    var wikiTitle: String?

    @State private var image: UIImage?

    private var loadKey: String {
        "\(urlString ?? "")|\(wikiTitle ?? "")"
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipped()
            } else {
                heroPlaceholder
            }
        }
        .task(id: loadKey) {
            await loadImage()
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

    private func loadImage() async {
        image = nil
        let loaded = await WikiPersonImageService.shared.image(
            primaryURL: urlString,
            wikiTitle: wikiTitle,
            width: 800
        )
        await MainActor.run { image = loaded }
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
