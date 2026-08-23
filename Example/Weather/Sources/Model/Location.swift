import Foundation

/// A place the user follows. `Codable` and `Hashable` so it can travel as
/// a route payload on coordinators that opt into `codable: true` state
/// restoration.
struct Location: Identifiable, Codable, Hashable, Sendable {
    /// Stable slug — also the deep-link token (`weather://location/prague`).
    let id: String
    let name: String
    let country: String

    /// Deterministic seed for the fake forecast generator.
    var seed: Int {
        id.unicodeScalars.reduce(0) { $0 &* 31 &+ Int($1.value) }
    }
}

extension Location {
    static let prague = Location(id: "prague", name: "Prague", country: "Czechia")
    static let tokyo = Location(id: "tokyo", name: "Tokyo", country: "Japan")
    static let oslo = Location(id: "oslo", name: "Oslo", country: "Norway")

    /// The initially saved locations.
    static let defaults: [Location] = [.prague, .tokyo, .oslo]

    /// Cities offered by the add-location search flow.
    static let searchable: [Location] = [
        Location(id: "lisbon", name: "Lisbon", country: "Portugal"),
        Location(id: "sydney", name: "Sydney", country: "Australia"),
        Location(id: "nairobi", name: "Nairobi", country: "Kenya"),
        Location(id: "reykjavik", name: "Reykjavík", country: "Iceland"),
        Location(id: "quito", name: "Quito", country: "Ecuador"),
        Location(id: "taipei", name: "Taipei", country: "Taiwan"),
    ]
}
