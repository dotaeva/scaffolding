import Foundation

public enum Landscape: String, Codable, Sendable { case alpine, coast, garden }

public struct Place: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let region: String
    public let caption: String
    public let story: String
    public let coordinates: String
    public let landscape: Landscape
    public let highlights: [String]
}

/// Editorial sample content bundled with the demo; no service or account needed.
public enum PlaceCatalog {
    public static let all: [Place] = [
        Place(id: "dolomites", name: "The Dolomites", region: "Italy",
              caption: "A little closer to the sky.",
              story: "Early light on limestone peaks. A trail that takes the long way home. Leave room for a slow lunch and an unplanned turn.",
              coordinates: "46°29′ N  11°51′ E", landscape: .alpine,
              highlights: ["Follow the morning light", "Take the scenic route", "Find a table with a view"]),
        Place(id: "kyoto", name: "Kyoto", region: "Japan",
              caption: "Find the beauty in between.",
              story: "Small gardens behind wooden doors. Tea that deserves your full attention. A city best discovered one quiet street at a time.",
              coordinates: "35°00′ N  135°46′ E", landscape: .garden,
              highlights: ["Start in a quiet garden", "Make time for tea", "Wander without a destination"]),
        Place(id: "lofoten", name: "Lofoten", region: "Norway",
              caption: "Where the mountains meet the sea.",
              story: "Red cabins, open water, and a horizon that keeps changing. Pack a notebook. Leave the rest of the afternoon open.",
              coordinates: "68°12′ N  13°36′ E", landscape: .coast,
              highlights: ["Walk beside the water", "Sketch the changing horizon", "Watch the evening settle"])
    ]

    public static func place(_ id: String) -> Place? { all.first { $0.id == id } }
}
