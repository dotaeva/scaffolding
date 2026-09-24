import Foundation

public enum AtlasLayout: String, Codable, CaseIterable, Sendable { case tabs, split }

/// Feature-to-shell communication. Features know this contract, never the shell.
@MainActor
public protocol AtlasSelectionDelegate: AnyObject {
    var selectedPlaceID: String? { get }
    var selectedJourneyID: UUID? { get }
    func openPlace(_ id: String)
    func openJourney(_ id: UUID)
    func clearJourney(_ id: UUID)
}

/// Capabilities supplied by the composition root through weak references.
@MainActor
public protocol AtlasSessionActions: AnyObject {
    var layout: AtlasLayout { get }
    var hierarchyDescription: String { get }
    var hasCheckpoint: Bool { get }
    var checkpointDate: Date? { get }
    func startExploring()
    func restartWelcome()
    func switchLayout(_ layout: AtlasLayout)
    func openJourney(_ id: UUID)
    func openExampleLink()
    func saveCheckpoint()
    func restoreCheckpoint()
}

public enum AtlasLink: Equatable, Sendable {
    case place(String, highlights: Bool)

    public init?(url: URL) {
        guard url.scheme?.lowercased() == "atlas", url.host == "place" else { return nil }
        let path = url.pathComponents.filter { $0 != "/" }
        guard let id = path.first, PlaceCatalog.place(id) != nil,
              path.count == 1 || (path.count == 2 && path[1] == "highlights") else { return nil }
        self = .place(id, highlights: path.count == 2)
    }
}
