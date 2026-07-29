import SwiftUI

struct BirthdayBanner: View {
    let month: Int
    let day: Int

    private var isBirthdayToday: Bool {
        let today = Calendar.current.dateComponents([.month, .day], from: Date())
        return today.month == month && today.day == day
    }

    private var todayLabel: String {
        Date().formatted(.dateTime.month(.wide).day())
    }

    private var birthdayLabel: String {
        DateFormatting.birthdate(month: month, day: day)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isBirthdayToday ? "party.popper.fill" : "calendar")
                .foregroundStyle(BirthmateTheme.accent)

            VStack(alignment: .leading, spacing: 2) {
                if isBirthdayToday {
                    Text("Happy Birthday!")
                        .font(.subheadline.weight(.semibold))
                    Text("You're celebrating with everyone born on \(birthdayLabel).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Today is \(todayLabel)")
                        .font(.subheadline.weight(.medium))
                    Text("Your day is \(birthdayLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(BirthmateTheme.accent.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

struct LastUpdatedLabel: View {
    let date: Date?

    var body: some View {
        if let date {
            Text("Updated \(date.formatted(.relative(presentation: .named)))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
