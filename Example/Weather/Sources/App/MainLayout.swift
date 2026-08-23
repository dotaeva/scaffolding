import SwiftUI

/// Which shell the main experience uses.
///
/// iPhone gets a `TabCoordinatable`; iPad and macOS get a
/// `SplitCoordinatable` (master–detail). The decision is a value passed to
/// `AppCoordinator` so tests can construct either shape on any platform —
/// `MainLayout.current` is only the runtime default.
enum MainLayout: String, Codable, Sendable {
    /// iPhone: tab bar with one flow per tab.
    case tabs
    /// iPad / macOS: locations sidebar + forecast detail.
    case split

    static var current: MainLayout {
        #if os(macOS)
        .split
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? .split : .tabs
        #endif
    }
}
