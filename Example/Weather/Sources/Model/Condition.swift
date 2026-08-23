import SwiftUI

/// A sky condition with its SF Symbol and background palette.
enum Condition: String, Codable, CaseIterable, Sendable {
    case clear
    case partlyCloudy
    case cloudy
    case rain
    case storm
    case snow

    var name: String {
        switch self {
        case .clear: "Clear"
        case .partlyCloudy: "Partly Cloudy"
        case .cloudy: "Cloudy"
        case .rain: "Rain"
        case .storm: "Thunderstorms"
        case .snow: "Snow"
        }
    }

    var symbol: String {
        switch self {
        case .clear: "sun.max.fill"
        case .partlyCloudy: "cloud.sun.fill"
        case .cloudy: "cloud.fill"
        case .rain: "cloud.rain.fill"
        case .storm: "cloud.bolt.rain.fill"
        case .snow: "cloud.snow.fill"
        }
    }

    /// Top-to-bottom sky gradient used by `SkyBackground`.
    var gradient: [Color] {
        switch self {
        case .clear: [Color(red: 0.15, green: 0.45, blue: 0.85), Color(red: 0.45, green: 0.70, blue: 0.95)]
        case .partlyCloudy: [Color(red: 0.20, green: 0.40, blue: 0.70), Color(red: 0.50, green: 0.62, blue: 0.80)]
        case .cloudy: [Color(red: 0.30, green: 0.36, blue: 0.48), Color(red: 0.52, green: 0.57, blue: 0.66)]
        case .rain: [Color(red: 0.18, green: 0.24, blue: 0.38), Color(red: 0.35, green: 0.43, blue: 0.55)]
        case .storm: [Color(red: 0.10, green: 0.12, blue: 0.22), Color(red: 0.28, green: 0.30, blue: 0.44)]
        case .snow: [Color(red: 0.42, green: 0.52, blue: 0.68), Color(red: 0.72, green: 0.78, blue: 0.88)]
        }
    }
}
