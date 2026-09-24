import SwiftUI

@MainActor
public extension Destination {
    /// Closes this screen.
    ///
    /// Read the destination with `@Environment(\.destination)`. What closes
    /// depends on where the screen sits:
    ///
    /// | Screen | Effect |
    /// |---|---|
    /// | Pushed | Removes it and everything above it |
    /// | Presented | Closes that presentation |
    /// | Root of a flow or root coordinator | Dismisses the enclosing coordinator, as ``Coordinatable/dismissCoordinator()`` does |
    /// | Top-level root, tab, or split column | Nothing |
    /// | Already removed, or the preview placeholder | Nothing |
    ///
    /// A caller awaiting this route resumes with `nil`; use
    /// ``dismiss(returning:)`` to deliver a value. Native
    /// `@Environment(\.dismiss)` also works and returns no value.
    func dismiss() {
        dismissDestination(result: nil)
    }

    /// Closes this screen and returns `result` to the caller awaiting it.
    ///
    /// ```swift
    /// @Environment(\.destination) private var destination
    ///
    /// Button("Choose") { destination.dismiss(returning: selectedItem) }
    /// ```
    ///
    /// Removal follows ``dismiss()``. The value reaches
    /// ``FlowCoordinatable/route(to:policy:awaiting:)`` or
    /// ``Coordinatable/present(_:as:policy:awaiting:)`` when the awaited type
    /// matches; otherwise that call returns `nil`. Other removed destinations
    /// resume with `nil`. Calling it again does nothing.
    func dismiss<Result>(returning result: Result) {
        dismissDestination(result: result)
    }
}

@MainActor
private extension Destination {
    func dismissDestination(result: Any?) {
        guard !resolution.didResolve, let parent else { return }
        // Match the shared identity too: a copied, subsequently edited id
        // must never target a different destination in the same container.
        let matches: (Destination) -> Bool = {
            $0.id == id && $0.resolution === resolution
        }

        func dismissOwner() {
            if let result {
                parent.dismissCoordinator(returning: result)
            } else {
                parent.dismissCoordinator()
            }
        }

        if let flow = parent as? any FlowCoordinatable {
            let stack = flow._stack
            if let root = stack.root, matches(root) {
                dismissOwner()
            } else if let index = stack.destinations.firstIndex(where: matches) {
                if stack.destinations[index].routeType.isModal {
                    resolution.result = result
                    parent.removeOwnModals(where: matches)
                    return
                }
                let removed = Array(stack.destinations[index...])
                resolution.result = result
                withScaffoldingAnimation(stack.animation) {
                    stack.destinations.removeSubrange(index...)
                }
                resolveDismissals(removed)
            }
        } else if let root = parent as? any RootCoordinatable {
            let container = root._root
            if container.modals.contains(where: matches) {
                resolution.result = result
                parent.removeOwnModals(where: matches)
            } else if let destination = container.root, matches(destination) {
                dismissOwner()
            }
        } else if let tab = parent as? any TabCoordinatable {
            let container = tab._tabItems
            if container.modals.contains(where: matches) {
                resolution.result = result
                parent.removeOwnModals(where: matches)
            }
        } else if let split = parent as? any SplitCoordinatable {
            let container = split._columns
            if container.modals.contains(where: matches) {
                resolution.result = result
                parent.removeOwnModals(where: matches)
            }
        }
    }
}
