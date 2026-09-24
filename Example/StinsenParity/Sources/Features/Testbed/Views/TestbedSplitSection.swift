import SwiftUI
import Scaffolding

/// The `SplitCoordinatable` half of the testbed — present only when the
/// split shell is the one that was built.
///
/// This flow *is* the detail column, so every call here is visible without
/// leaving the screen. `setDetail` is deliberately absent: it would replace
/// the column this screen lives in, and the sidebar's re-selection guard
/// would then refuse to bring it back.
struct TestbedSplitSection: View {
    @Environment(AuthenticatedSplitCoordinator.self) private var split: AuthenticatedSplitCoordinator?

    /// `NavigationSplitViewVisibility` and `NavigationSplitViewColumn` are
    /// structs, not enums, so `String(describing:)` prints their whole
    /// memberwise description. They are `Equatable`, which is enough for
    /// `switch` to match their static members.
    private func label(_ value: NavigationSplitViewVisibility) -> String {
        switch value {
        case .all: "all"
        case .doubleColumn: "doubleColumn"
        case .detailOnly: "detailOnly"
        default: "automatic"
        }
    }

    private func label(_ value: NavigationSplitViewColumn) -> String {
        switch value {
        case .sidebar: "sidebar"
        case .content: "content"
        default: "detail"
        }
    }

    var body: some View {
        if let split {
            Section {
                ReadoutRow("sidebarDestination", caseLabel(split.sidebarDestination))
                ReadoutRow("contentDestination", caseLabel(split.contentDestination))
                ReadoutRow("detailDestination", caseLabel(split.detailDestination))
                ReadoutRow("hasContentColumn", String(split.anySplitColumns.hasContentColumn))
                ReadoutRow("columnVisibility", label(split.anySplitColumns.columnVisibility))
                ReadoutRow("preferredCompactColumn",
                           label(split.anySplitColumns.preferredCompactColumn))

                CallRow("toggleSidebar()", symbol: "sidebar.left") {
                    split.toggleSidebar()
                }
                CallRow("setColumnVisibility(.all)", symbol: "rectangle.split.3x1") {
                    split.setColumnVisibility(.all)
                }
                CallRow("setColumnVisibility(.detailOnly)", symbol: "rectangle") {
                    split.setColumnVisibility(.detailOnly)
                }
                CallRow("setContent(.todos) — install the middle column",
                        symbol: "rectangle.split.2x1") {
                    split.setContent(.todos)
                }
                CallRow("removeContent() — drop it again",
                        symbol: "rectangle.split.1x2") {
                    split.removeContent()
                }
                CallRow("setPreferredCompactColumn(.detail)", symbol: "iphone") {
                    split.setPreferredCompactColumn(.detail)
                }
                CallRow("setPreferredCompactColumn(.sidebar)",
                        symbol: "iphone.badge.play") {
                    split.setPreferredCompactColumn(.sidebar)
                }
            } header: {
                Text("Split shell")
            } footer: {
                Text("setContent/removeContent swap the container between "
                     + "NavigationSplitView's two- and three-column forms while "
                     + "you watch — the middle column appears next to this one, "
                     + "with no navigation of its own involved. "
                     + "preferredCompactColumn only shows once the split "
                     + "collapses, in Slide Over or a narrow Split View.")
            }
        }
    }
}
