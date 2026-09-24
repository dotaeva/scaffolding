import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The `SplitCoordinatable` calls the testbed's "Split shell" section
/// drives, all of them visible without leaving the detail column.
@MainActor
@Suite("Column controls")
struct ColumnControlTests {
    private func makeSplit() -> AuthenticatedSplitCoordinator {
        AuthenticatedSplitCoordinator(user: .preview, toasts: ToastCenter()).activated()
    }

    @Test("the content column installs and drops while another section shows")
    func contentColumn() {
        let split = makeSplit()
        split.select(.testbed)
        #expect(!split.anySplitColumns.hasContentColumn)

        split.setContent(.todos)
        #expect(split.anySplitColumns.hasContentColumn)
        #expect(split.contentDestination == .todos)
        // The detail column is untouched: the testbed is still showing.
        #expect(split.isDetail(.testbed))

        split.removeContent()
        #expect(!split.anySplitColumns.hasContentColumn)
        #expect(split.isDetail(.testbed))
    }

    @Test("column visibility is coordinator state, not view state")
    func visibility() {
        let split = makeSplit()

        split.setColumnVisibility(.detailOnly)
        #expect(split.anySplitColumns.columnVisibility == .detailOnly)

        split.toggleSidebar()
        #expect(split.anySplitColumns.columnVisibility != .detailOnly)

        split.setPreferredCompactColumn(.detail)
        #expect(split.anySplitColumns.preferredCompactColumn == .detail)
    }
}
