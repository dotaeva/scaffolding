import Foundation
import Observation

public enum TravelPace: String, CaseIterable, Codable, Sendable {
    case unhurried = "Unhurried", balanced = "A little of both", adventurous = "See it all"
    public var detail: String {
        switch self {
        case .unhurried: "Slow mornings and room to wander."
        case .balanced: "A few highlights, with time in between."
        case .adventurous: "Full days and new discoveries."
        }
    }
}

public struct TripPlan: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let placeID: String
    public let days: Int
    public let pace: TravelPace

    public init(id: UUID = UUID(), placeID: String, days: Int, pace: TravelPace) {
        self.id = id; self.placeID = placeID; self.days = days; self.pace = pace
    }
}

public struct AtlasData: Codable, Equatable, Sendable {
    public var savedIDs: Set<String>
    public var plans: [TripPlan]
    public var hasStarted: Bool

    public init(savedIDs: Set<String> = ["kyoto"], plans: [TripPlan] = [], hasStarted: Bool = false) {
        self.savedIDs = savedIDs; self.plans = plans; self.hasStarted = hasStarted
    }

    enum CodingKeys: String, CodingKey { case savedIDs, plans, hasStarted }
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        savedIDs = try values.decode(Set<String>.self, forKey: .savedIDs)
        plans = try values.decode([TripPlan].self, forKey: .plans)
        hasStarted = try values.decodeIfPresent(Bool.self, forKey: .hasStarted) ?? false
    }
}

/// Durable domain content, shared by windows. Navigation remains window-owned.
@MainActor @Observable
public final class AtlasStore {
    public private(set) var savedIDs: Set<String> = ["kyoto"]
    public private(set) var plans: [TripPlan] = []
    public private(set) var hasStarted = false
    public private(set) var persistenceError: String?
    private let storageURL: URL?
    private var unreadableCollection = false

    /// Omit the URL for isolated previews and tests.
    public init(storageURL: URL? = nil, reset: Bool = false) {
        self.storageURL = storageURL
        guard let storageURL else { return }
        if reset { persist(); return }
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            apply(try JSONDecoder().decode(AtlasData.self, from: Data(contentsOf: storageURL)))
        } catch {
            unreadableCollection = true
            persistenceError = "Your saved collection could not be opened. The original file has been kept."
        }
    }

    public var savedPlaces: [Place] { PlaceCatalog.all.filter { savedIDs.contains($0.id) } }
    public var snapshot: AtlasData { AtlasData(savedIDs: savedIDs, plans: plans, hasStarted: hasStarted) }
    public func plan(_ id: UUID) -> TripPlan? { plans.first { $0.id == id } }

    public func markStarted() { guard !hasStarted else { return }; hasStarted = true; persist() }
    public func toggleSaved(_ id: String) {
        guard PlaceCatalog.place(id) != nil else { return }
        if savedIDs.contains(id) { savedIDs.remove(id) } else { savedIDs.insert(id) }
        persist()
    }
    public func add(_ plan: TripPlan) {
        guard valid(plan), !plans.contains(where: { $0.id == plan.id }) else { return }
        plans.insert(plan, at: 0)
        persist()
    }
    @discardableResult public func update(_ plan: TripPlan) -> Bool {
        guard valid(plan), let index = plans.firstIndex(where: { $0.id == plan.id }) else { return false }
        plans[index] = plan
        persist()
        return true
    }
    public func remove(_ id: UUID) { plans.removeAll { $0.id == id }; persist() }

    private func valid(_ plan: TripPlan) -> Bool { PlaceCatalog.place(plan.placeID) != nil && (1...14).contains(plan.days) }
    private func apply(_ data: AtlasData) {
        savedIDs = data.savedIDs.filter { PlaceCatalog.place($0) != nil }
        var seen = Set<UUID>()
        plans = data.plans.filter { valid($0) && seen.insert($0.id).inserted }
        hasStarted = data.hasStarted
    }
    private func persist() {
        guard let storageURL else { return }
        // Do not overwrite an unreadable collection with a newly initialized one.
        guard !unreadableCollection else { return }
        do {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try JSONEncoder().encode(snapshot).write(to: storageURL, options: .atomic)
            persistenceError = nil
        } catch {
            persistenceError = "Changes are available in this session, but could not be saved to disk."
        }
    }
}
