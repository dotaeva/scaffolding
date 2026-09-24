import SwiftUI
import Scaffolding

// MARK: - Modals

extension TestbedCoordinator {
    /// The route's view applies its native SwiftUI sheet modifiers.
    func presentScreen() {
        Task { [weak self] in
            guard let self else { return }
            // A repeated tap must not report an immediate "dismissal".
            guard !isInStack(.sheet), !Task.isCancelled else { return }
            _ = await present(.sheet(label: "Sheet", expanded: true), awaiting: Void.self)
            guard !Task.isCancelled else { return }
            toasts.showNeutral("Sheet dismissed", symbol: "rectangle.portrait.slash")
        }
    }

    func presentCover() {
        present(.screen(label: "Cover"), as: .fullScreenCover, policy: .distinct)
    }

    /// Swipe-down disabled: only the presenter can close this one.
    ///
    /// Which leaves two ways out, both of them presenter-side. A toast
    /// draws in its own window above the sheet, so the escape can ship
    /// with the presentation; and every ancestor coordinator is in the
    /// presented screen's environment, so the sheet itself can call
    /// `dismissModal()` on whoever presented it. A control on the
    /// presenting screen could do neither — it is covered exactly when it
    /// becomes useful.
    func presentLockedSheet() {
        present(.lockedSheet)
        toasts.show(
            "Locked sheet — swipe-down is off",
            symbol: "lock.fill",
            tint: .orange,
            actionTitle: "dismissModal()"
        ) { [weak self] in
            self?.dismissModal()
        }
    }

    /// Two modals presented back to back.
    ///
    /// A flow renders one modal at a time, so the second waits behind the
    /// first. `dismissModal()` peels them off one at a time and
    /// `dismissAllModals()` clears the lot — a difference only visible with
    /// more than one in flight, which is why it is offered from the toast
    /// and from the sheet, never from the screen that queued them.
    func presentStackedSheets() {
        present(.sheet(label: "First", expanded: false))
        present(.sheet(label: "Second", expanded: false))

        toasts.show(
            "Two sheets queued — one shows at a time",
            symbol: "square.stack.3d.up.fill",
            tint: .orange,
            actionTitle: "dismissAllModals()"
        ) { [weak self] in
            self?.dismissAllModals()
            self?.toasts.showNeutral("Both sheets cleared in one call")
        }
    }

    /// A whole coordinator presented modally: it gets its own stack, so
    /// the testbed inside it pushes independently of this one.
    func presentChild() {
        present(.childTestbed, as: .sheet, policy: .distinct)
    }
}
