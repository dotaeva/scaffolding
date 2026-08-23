import Foundation

/// One hour of a day's forecast.
struct HourForecast: Identifiable, Codable, Hashable, Sendable {
    /// 0–23.
    let hour: Int
    let condition: Condition
    let temperatureC: Int

    var id: Int { hour }

    var label: String {
        switch hour {
        case 0: "12AM"
        case 1...11: "\(hour)AM"
        case 12: "12PM"
        default: "\(hour - 12)PM"
        }
    }
}
