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
        HStack(spacing: 12) {
            Image(systemName: isBirthdayToday ? "party.popper.fill" : "calendar")
                .font(.title3)
                .foregroundStyle(BirthmateTheme.accent)
                .symbolEffect(.bounce, value: isBirthdayToday)

            VStack(alignment: .leading, spacing: 3) {
                if isBirthdayToday {
                    Text("Happy Birthday!")
                        .font(.headline)
                    Text("You're celebrating with everyone born on \(birthdayLabel).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Today is \(todayLabel)")
                        .font(.subheadline.weight(.semibold))
                    Text("Your day is \(birthdayLabel)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .background {
            if isBirthdayToday {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BirthmateTheme.birthdayGradient)
            } else {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(BirthmateTheme.accent.opacity(0.1))
            }
        }
        .overlay {
            if isBirthdayToday {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(BirthmateTheme.accent.opacity(0.25), lineWidth: 1)
            }
        }
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
