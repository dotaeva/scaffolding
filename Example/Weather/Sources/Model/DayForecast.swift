import Foundation

/// One day of a location's ten-day forecast.
///
/// Travels as a route payload (`day(day: DayForecast)`), so it is
/// `Codable` (for `codable: true` restoration) and `Hashable`.
struct DayForecast: Identifiable, Codable, Hashable, Sendable {
    /// Offset from today; 0 is today.
    let index: Int
    let weekday: String
    let condition: Condition
    let highC: Int
    let lowC: Int
    let hours: [HourForecast]

    var id: Int { index }

    var name: String {
        switch index {
        case 0: "Today"
        case 1: "Tomorrow"
        default: weekday
        }
    }

    var summary: String {
        "\(condition.name) for most of the day, cooling off overnight."
    }
}
