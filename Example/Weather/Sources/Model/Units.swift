import Foundation

/// Temperature units, chosen during onboarding and changeable from
/// Settings via the awaiting-picker flow.
enum Units: String, Codable, CaseIterable, Identifiable, Sendable {
    case celsius
    case fahrenheit

    var id: String { rawValue }

    var label: String {
        switch self {
        case .celsius: "Celsius (°C)"
        case .fahrenheit: "Fahrenheit (°F)"
        }
    }

    /// Formats a Celsius value in these units, e.g. `21°` / `70°`.
    func format(_ celsius: Int) -> String {
        switch self {
        case .celsius: "\(celsius)°"
        case .fahrenheit: "\(celsius * 9 / 5 + 32)°"
        }
    }
}
