import Foundation

/// Deterministic fake forecasts — no network, no entitlements, stable
/// across launches so navigation state restoration always lands on data
/// that still exists.
enum ForecastEngine {
    /// Ten days of weather for a location, seeded by its identity.
    static func tenDays(for location: Location) -> [DayForecast] {
        (0..<10).map { day(at: $0, seed: location.seed) }
    }

    static func day(at index: Int, seed: Int) -> DayForecast {
        let base = value(seed, index, 0)
        let conditions = Condition.allCases
        let condition = conditions[base % conditions.count]
        let high = 8 + (value(seed, index, 1) % 22)          // 8…29 °C
        let low = high - 4 - (value(seed, index, 2) % 8)     // 4…11 below

        let hours = (0..<24).map { hour -> HourForecast in
            let wobble = value(seed, index, 10 + hour) % 5
            let warm = hour >= 10 && hour <= 17
            return HourForecast(
                hour: hour,
                condition: hour % 7 == wobble ? condition : .partlyCloudy,
                temperatureC: warm ? high - wobble : low + wobble
            )
        }

        return DayForecast(
            index: index,
            weekday: weekday(at: index),
            condition: condition,
            highC: high,
            lowC: low,
            hours: hours
        )
    }

    private static func weekday(at index: Int) -> String {
        let names = Calendar.current.weekdaySymbols
        let today = Calendar.current.component(.weekday, from: .now) - 1
        return names[(today + index) % names.count]
    }

    /// Small deterministic hash, always positive.
    private static func value(_ seed: Int, _ a: Int, _ b: Int) -> Int {
        var x = seed &+ a &* 7_919 &+ b &* 104_729
        x = (x ^ (x >> 15)) &* 2_654_435_761
        return abs(x % 1_000_003)
    }
}
