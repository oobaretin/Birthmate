import SwiftUI

enum WikiImageLoader {
    static func load(from urlString: String?) async -> (UIImage?, String) {
        guard let resolved = WikiImageURL.resolved(urlString) else {
            return (nil, "resolve_nil")
        }
        guard let url = WikiImageURL.url(from: resolved) else {
            return (nil, "url_parse_failed:\(resolved.prefix(80))")
        }

        var request = URLRequest(url: url)
        request.setValue("Birthmate/1.0 (iOS app; contact: github.com/oobaretin/Birthmate)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return (nil, "no_http_response")
            }
            guard (200...299).contains(http.statusCode) else {
                return (nil, "http_\(http.statusCode)")
            }
            guard let image = UIImage(data: data) else {
                return (nil, "decode_failed:\(data.count)b")
            }
            return (image, "ok:\(data.count)b")
        } catch {
            return (nil, "error:\(error.localizedDescription)")
        }
    }
}

struct PersonThumbnailView: View {
    let urlString: String?
    var wikiTitle: String?
    var size: CGFloat = 56

    @State private var image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
            } else {
                Circle()
                    .fill(BirthmateTheme.accent.opacity(0.15))
                    .overlay(
                        Image(systemName: "person.fill")
                            .foregroundStyle(BirthmateTheme.accent)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: loadKey) {
            await loadImage()
        }
    }

    private var loadKey: String {
        "\(urlString ?? "")|\(wikiTitle ?? "")"
    }

    private func loadImage() async {
        image = nil
        let (direct, directReason) = await WikiImageLoader.load(from: urlString)
        if let direct {
            await MainActor.run { image = direct }
            logLoad(outcome: "direct", detail: directReason, displayed: true)
            return
        }
        if let title = wikiTitle {
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
            if let fallback = await WikipediaSummaryService.shared.fetchThumbnailURL(for: item) {
                let (loaded, reason) = await WikiImageLoader.load(from: fallback)
                if let loaded {
                    await MainActor.run { image = loaded }
                    logLoad(outcome: "wikipedia_fallback", detail: reason, displayed: true)
                    return
                }
                logLoad(outcome: "fallback_load_failed", detail: reason, displayed: false)
            } else {
                logLoad(outcome: "fallback_url_nil", detail: directReason, displayed: false)
            }
        } else {
            logLoad(outcome: "failed", detail: directReason, displayed: false)
        }
    }

    #if DEBUG
    private static var logCount = 0
    private func logLoad(outcome: String, detail: String, displayed: Bool) {
        guard Self.logCount < 12 else { return }
        Self.logCount += 1
        AgentDebugLog.log(
            location: "FeedStateViews.swift:PersonThumbnailView",
            message: "Image load",
            data: [
                "outcome": outcome,
                "detail": String(detail.prefix(100)),
                "displayed": displayed ? "true" : "false",
                "url": String((urlString ?? "nil").prefix(100))
            ],
            hypothesisId: "F"
        )
    }
    #else
    private func logLoad(outcome: String, detail: String, displayed: Bool) {}
    #endif
}

struct PersonHeroImageView: View {
    let urlString: String?
    var wikiTitle: String?

    @State private var image: UIImage?

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
                Rectangle()
                    .fill(BirthmateTheme.accent.opacity(0.12))
                    .frame(height: 180)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(BirthmateTheme.accent.opacity(0.5))
                    )
            }
        }
        .task(id: "\(urlString ?? "")|\(wikiTitle ?? "")") {
            await loadImage()
        }
    }

    private func loadImage() async {
        image = nil
        let candidates = [
            WikiImageURL.resolved(urlString, width: 800),
            urlString.flatMap { WikiImageURL.resolved($0) }
        ].compactMap { $0 }

        for candidate in candidates {
            let (loaded, _) = await WikiImageLoader.load(from: candidate)
            if let loaded {
                await MainActor.run { image = loaded }
                return
            }
        }
        if let title = wikiTitle {
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
            if let fallback = await WikipediaSummaryService.shared.fetchThumbnailURL(for: item) {
                let (loaded, _) = await WikiImageLoader.load(from: fallback)
                if let loaded {
                    await MainActor.run { image = loaded }
                }
            }
        }
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
