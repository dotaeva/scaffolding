import SwiftUI

/// Which shell the signed-in tree uses.
///
/// The Stinsen demo only ever builds the tab shell. Scaffolding lets the
/// same four flows be hosted either way, so the choice is a value handed
/// to ``MainCoordinator`` rather than a `#if` sprinkled through the app —
/// which also lets a test build either shape on any device.
enum ShellLayout: String, Sendable {
    /// iPhone: four tabs, one flow each.
    case tabs
    /// iPad: a sidebar, a task column that comes and goes, and a detail
    /// column.
    case split

    static var current: ShellLayout {
        UIDevice.current.userInterfaceIdiom == .pad ? .split : .tabs
    }
}
