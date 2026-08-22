import SwiftUI
import Observation
import Scaffolding

// MARK: - Modals and visibility

extension SolarSystemCoordinator {
    /// A multi-step sub-flow presented ABOVE the whole split view — same
    /// API as on tab and root coordinators. (A single-screen modal would
    /// stay a native .sheet in the view, as always.)
    func openSettings() {
        present(.settings, as: .sheet)
    }

    /// Programmatic column visibility. Interactive changes — the system
    /// sidebar toggle, edge swipes — write back into `columnVisibility`,
    /// so coordinator state and screen never drift apart.
    func focusOnDetail() {
        setColumnVisibility(.detailOnly)
    }

    /// The macOS-style flip: hides the sidebar when `isSidebarVisible`,
    /// restores `.all` otherwise. Wire it to a toolbar button or a menu
    /// command (SidebarCommands() on macOS does the same natively).
    func toggleSidebarFromMenu() {
        toggleSidebar()
    }
}
