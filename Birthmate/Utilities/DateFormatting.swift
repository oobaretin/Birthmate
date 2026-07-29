import Foundation

enum DateFormatting {
    static func birthdate(month: Int, day: Int) -> String {
        var components = DateComponents()
        components.year = 2024
        components.month = month
        components.day = day
        guard let date = Calendar.current.date(from: components) else { return "" }
        return date.formatted(.dateTime.month(.wide).day())
    }

    static func birthdateShort(month: Int, day: Int) -> String {
        "\(Calendar.current.monthSymbols[month - 1]) \(day)"
    }
}
