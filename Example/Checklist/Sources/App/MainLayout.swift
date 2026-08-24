import SwiftUI

/// Which shell the main experience uses.
///
/// iPhone gets a ``TabCoordinatable``; iPad and Mac get a
/// ``SplitCoordinatable`` (three columns: lists → tasks → task). The
/// decision is a value handed to `AppCoordinator`, so tests can build
/// either shape on any platform — `MainLayout.current` is only the
/// runtime default.
enum MainLayout: String, Codable, Sendable {
    /// iPhone: tab bar, one flow per tab.
    case tabs
    /// iPad / macOS: sidebar + task list + task detail.
    case split

    static var current: MainLayout {
        #if os(macOS)
        .split
        #else
        UIDevice.current.userInterfaceIdiom == .pad ? .split : .tabs
        #endif
    }
}
