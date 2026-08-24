import SwiftUI
import Scaffolding

// MARK: - Modals and awaited navigation

extension PlaygroundCoordinator {
    /// The presenter picks the chrome: detents and a drag indicator here.
    func presentSheet() {
        present(.sheet, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }

    /// A cover on iOS; macOS has none, so Scaffolding renders it as a
    /// sheet and the state still reports `.fullScreenCover`.
    func presentCover() {
        present(.cover, as: .fullScreenCover, policy: .distinct)
    }

    /// Swipe-down disabled — only the presenter can close this one.
    func presentLockedSheet() {
        present(.sheet, as: .sheet(detents: [.medium], interactiveDismissDisabled: true))
    }

    /// `present(_:awaiting:)` suspends until the sub-flow hands a value
    /// back with `dismissCoordinator(returning:)`; any other dismissal
    /// resumes with `nil`, so cancelling needs no extra channel.
    func awaitPicker() {
        Task {
            let picked = await present(.picker, as: .sheet(detents: [.medium]), awaiting: Int.self)
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

    /// `presentAndWait`: same idea for a modal, with no value to carry.
    func presentAndWaitSheet() {
        Task {
            lastResult = "waiting for the sheet…"
            await presentAndWait(.sheet, as: .sheet(detents: [.medium]))
            lastResult = "sheet dismissed"
        }
    }

    func resetReadouts() {
        lastResult = nil
        dismissals = 0
    }
}
