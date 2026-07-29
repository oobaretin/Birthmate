import WidgetKit
import SwiftUI

struct BirthmateWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct BirthmateWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BirthmateWidgetEntry {
        BirthmateWidgetEntry(
            date: Date(),
            snapshot: WidgetSnapshot(
                month: 8, day: 26, totalCount: 842,
                featuredName: "Macaulay Culkin", featuredYear: 1980,
                updatedAt: Date()
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (BirthmateWidgetEntry) -> Void) {
        completion(BirthmateWidgetEntry(date: Date(), snapshot: WidgetDataStore.loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BirthmateWidgetEntry>) -> Void) {
        let entry = BirthmateWidgetEntry(date: Date(), snapshot: WidgetDataStore.loadSnapshot())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date().addingTimeInterval(3600)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct BirthmateWidgetView: View {
    let entry: BirthmateWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            content(for: snapshot)
        } else if let birthdate = WidgetDataStore.loadBirthdate() {
            VStack(alignment: .leading, spacing: 6) {
                Label("Birthmate", systemImage: "gift.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.pink)
                Text(DateFormattingWidget.label(month: birthdate.month, day: birthdate.day))
                    .font(.headline)
                Text("Open Birthmate to load your birthmates.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Label("Birthmate", systemImage: "gift.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.pink)
                Text("Set your birthday")
                    .font(.headline)
                Text("Open the app to get started.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func content(for snapshot: WidgetSnapshot) -> some View {
        switch family {
        case .systemMedium:
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Label("Birthmate", systemImage: "gift.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.pink)
                    Text(snapshot.dateLabel)
                        .font(.headline)
                    Text("\(snapshot.totalCount) birthmates")
                        .font(.title2.bold())
                }
                Spacer()
                if let name = snapshot.featuredName {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Featured")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(2)
                        if let year = snapshot.featuredYear {
                            Text("Born \(String(year))")
                                .font(.caption)
                                .foregroundStyle(.pink)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        default:
            VStack(alignment: .leading, spacing: 6) {
                Label("Birthmate", systemImage: "gift.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.pink)
                Text(snapshot.dateLabel)
                    .font(.headline)
                Text("\(snapshot.totalCount) birthmates")
                    .font(.title3.bold())
                if let name = snapshot.featuredName {
                    Text(name)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}

private enum DateFormattingWidget {
    static func label(month: Int, day: Int) -> String {
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(.dateTime.month(.wide).day())
    }
}

struct BirthmateWidget: Widget {
    let kind = "BirthmateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BirthmateWidgetProvider()) { entry in
            BirthmateWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Birthmate")
        .description("See how many people share your birth day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
