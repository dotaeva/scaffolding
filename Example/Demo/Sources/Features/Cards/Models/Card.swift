import SwiftUI

/// Route payload — Codable so CardsCoordinator can opt into
/// @Scaffoldable(codable: true) state restoration.
struct Card: Identifiable, Hashable, Codable {
    let id: Int
    let holder: String
    let suffix: String
    let design: Design

    // Color isn't Codable — store a named design instead.
    enum Design: String, Codable {
        case violet, teal

        var colors: [Color] {
            switch self {
            case .violet: [Color(red: 0.35, green: 0.20, blue: 0.85), Color(red: 0.75, green: 0.25, blue: 0.65)]
            case .teal: [Color(red: 0.10, green: 0.45, blue: 0.55), Color(red: 0.05, green: 0.25, blue: 0.40)]
            }
        }
    }

    static let samples: [Card] = [
        Card(id: 0, holder: "ALEX RIVERA", suffix: "4821", design: .violet),
        Card(id: 1, holder: "ALEX RIVERA", suffix: "0774", design: .teal),
    ]
}
