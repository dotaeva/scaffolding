import Foundation

/// Persistence for hand-taken navigation snapshots (the shake menu's
/// Save/Restore), kept separate from the scene-restoration state `DemoApp`
/// writes on backgrounding.
///
/// The payload is the opaque `Data` from `captureNavigationState()` — treat it
/// as a blob; never construct or edit it.
struct NavigationSnapshotStore {
    private let dataKey = "nav-snapshot"
    private let dateKey = "nav-snapshot-date"
    private let defaults = UserDefaults.standard

    var data: Data? { defaults.data(forKey: dataKey) }
    var savedAt: Date? { defaults.object(forKey: dateKey) as? Date }
    var hasSnapshot: Bool { data != nil }

    func save(_ data: Data, at date: Date) {
        defaults.set(data, forKey: dataKey)
        defaults.set(date, forKey: dateKey)
    }

    func clear() {
        defaults.removeObject(forKey: dataKey)
        defaults.removeObject(forKey: dateKey)
    }
}
