import SwiftUI
import Scaffolding

// MARK: - Modals and awaited navigation

extension PlaygroundCoordinator {
    /// The presented view owns its detents and drag indicator.
    func presentSheet() {
        present(.sheet, as: .sheet, policy: .distinct)
    }

    /// A cover on iOS; macOS has none, so Scaffolding renders it as a
    /// sheet and the state still reports `.fullScreenCover`.
    func presentCover() {
        present(.cover, as: .fullScreenCover, policy: .distinct)
    }

    /// Swipe-down disabled — only the presenter can close this one.
    func presentLockedSheet() {
        present(.lockedSheet)
    }

    /// Two modals presented back to back.
    ///
    /// A flow renders one at a time, so the second waits behind the first:
    /// `dismissModal()` peels them off one by one, `dismissAllModals()`
    /// clears both at once. The difference only exists with more than one
    /// in flight — which is why the buttons for it live *inside* the modal
    /// rather than on this screen, where a presented sheet would cover
    /// them exactly when they became useful.
    func presentTwoSheets() {
        present(.sheet, as: .sheet)
        present(.cover, as: .sheet)
    }

    /// `present(_:awaiting:)` suspends until the sub-flow hands a value
    /// back with `dismissCoordinator(returning:)`; any other dismissal
    /// resumes with `nil`, so cancelling needs no extra channel.
    func awaitPicker() {
        Task {
            let picked = await present(.picker, as: .sheet, awaiting: Int.self)
            lastResult = picked.map { "picker returned \($0)" } ?? "picker cancelled"
        }
    }

    /// `routeAndWait` pushes and suspends until that screen leaves the
    /// stack, however it leaves.
    func routeAndWaitLeaf() {
        Task {
            lastResult = "waiting for the pushed leaf…"
            await routeAndWait(to: .leaf(label: "Awaited"))
            lastResult = "awaited leaf popped"
        }
    }

    /// `awaiting: Void.self`: wait for a modal, with no value to carry.
    func presentAndWaitSheet() {
        Task {
            lastResult = "waiting for the sheet…"
            _ = await present(.sheet, awaiting: Void.self)
            lastResult = "sheet dismissed"
        }
    }

    func resetReadouts() {
        lastResult = nil
        dismissals = 0
    }
}
