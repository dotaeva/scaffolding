import Foundation

/// A severe-weather warning the user has to acknowledge — presented as a
/// sheet with interactive dismissal disabled (see SevereAlertSheet).
struct WeatherAlert: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let message: String
    let locationName: String

    /// The demo starts with one unacknowledged alert so the badge and the
    /// radar-tab guard have something to show.
    static let sample = WeatherAlert(
        id: "storm-prague",
        title: "Severe Thunderstorm Warning",
        message: "Damaging winds and hail possible until 9PM. "
            + "Stay indoors and away from windows.",
        locationName: Location.prague.name
    )
}
