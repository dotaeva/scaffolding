import SwiftUI
import Scaffolding

// MARK: - Awaited navigation
// Each of these suspends until its destination leaves, then reports the
// outcome as a toast — which is the only honest way to *see* that an
// await resumed, since the screen that started it is usually gone.

extension TestbedCoordinator {
    /// Pushes and suspends until that screen leaves the stack, however it
    /// leaves — a pop, a back swipe, a root swap.
    func awaitPush() {
        Task {
            await routeAndWait(to: .screen(label: "Awaited push"))
            toasts.show("routeAndWait resumed — the screen was popped",
                        symbol: "arrow.uturn.backward.circle.fill")
        }
    }

    /// Same idea for a modal, with no value to carry back.
    func awaitSheet() {
        Task {
            _ = await present(.sheet(label: "Awaited sheet", expanded: false), awaiting: Void.self)
            toasts.show("awaiting: Void.self resumed — the sheet closed",
                        symbol: "rectangle.portrait.badge.checkmark")
        }
    }

    /// The one that carries a value. The picker hands a number back with
    /// `dismissCoordinator(returning:)`; any other dismissal resumes with
    /// `nil`, so cancelling needs no second channel.
    func awaitPicker() {
        Task {
            let picked = await present(
                .picker,
                as: .sheet,
                awaiting: Int.self
            )

            if let picked {
                toasts.show("The picker returned \(picked)", symbol: "number.circle.fill")
            } else {
                toasts.showNeutral("The picker was cancelled — resumed with nil")
            }
        }
    }
}

// MARK: - Dismissal

extension TestbedCoordinator {
    /// A tab's root coordinator has nowhere to go, exactly like the
    /// Stinsen screen's disabled "Dismiss coordinator" button.
    var canDismissSelf: Bool {
        routeType != .root
    }

    /// Removes this *whole coordinator* from its parent — not one screen.
    func dismissSelf() {
        dismissCoordinator()
    }

    func resetReadouts() {
        dismissals = 0
    }
}
