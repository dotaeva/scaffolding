//
//  FlowStack.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A type-erased protocol for ``FlowStack`` that allows the framework
/// to manipulate navigation state without knowing the concrete coordinator
/// type.
@MainActor
public protocol AnyFlowStack: AnyObject, CoordinatableData where Coordinator: FlowCoordinatable {
    /// The root destination of the navigation stack.
    var root: Destination? { get set }
    /// The ordered list of pushed destinations.
    var destinations: [Destination] { get set }
    /// The default animation applied to root transitions.
    var animation: Animation? { get set }
    /// The presentation type if this stack was presented modally.
    var presentedAs: PresentationType? { get set }
}

/// Observable state container for a ``FlowCoordinatable`` coordinator.
///
/// `FlowStack` holds the root destination and the array of pushed
/// destinations that form the navigation stack. It is generic over the
/// coordinator type so that destination enums remain type-safe.
///
/// ```swift
/// var stack = FlowStack<HomeCoordinator>(root: .home)
/// ```
@MainActor
@Observable
public class FlowStack<Coordinator: FlowCoordinatable>: AnyFlowStack {
    /// The root destination displayed at the bottom of the stack.
    public var root: Destination?
    /// The parent coordinator that owns this flow, if any.
    public weak var parent: (any Coordinatable)?
    /// Whether a parent flow coordinator provides the `NavigationStack`.
    public var hasLayerNavigationCoordinator: Bool = false
    /// The default animation used for root transitions.
    public var animation: Animation? = .default
    /// The presentation type when this flow was presented modally.
    public var presentedAs: PresentationType?

    /// The ordered list of pushed destinations above the root.
    public var destinations: [Destination] = .init()

    /// Whether ``setup(for:)`` has been called.
    public var isSetup: Bool = false
    private var initialRoot: Coordinator.Destinations?
    private var initialPath: [Coordinator.Destinations] = []
    private var coordinator: Coordinator?

    /// Creates a new flow stack with the given initial root destination.
    ///
    /// - Parameter root: The destination case to display as the root.
    public init(root: Coordinator.Destinations) {
        self.initialRoot = root
    }

    /// Creates a new flow stack with the given root and an initial path of
    /// pushed destinations above it.
    ///
    /// The path is materialised when the stack is first set up — use this
    /// to restore a flow to a deep position on cold launch, seed a preview
    /// mid-flow, or construct a coordinator already showing a detail
    /// screen:
    ///
    /// ```swift
    /// var stack = FlowStack<HomeCoordinator>(
    ///     root: .home,
    ///     pushing: [.detail(item: restored)]
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - root: The destination case to display as the root.
    ///   - path: Destinations pushed on top of the root, bottom first.
    public init(root: Coordinator.Destinations, pushing path: [Coordinator.Destinations]) {
        self.initialRoot = root
        self.initialPath = path
    }

    /// Performs one-time setup, resolving the initial root destination.
    ///
    /// - Parameter coordinator: The coordinator that owns this stack.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        self.coordinator = coordinator
        if let rootDestination = initialRoot, root == nil {
            var rootDest = rootDestination.resolvedValue(for: coordinator)

            _warnIfSplitInsideNavigationStack(rootDest.coordinatable)
            rootDest.coordinatable?.setHasLayerNavigationCoordinatable(true)
            rootDest.coordinatable?.setParent(coordinator)

            if let presentedAs = presentedAs {
                rootDest.setPushType(presentedAs)
            }

            root = rootDest
            self.initialRoot = nil
        }
        if !initialPath.isEmpty {
            for element in initialPath {
                var dest = element.resolvedValue(for: coordinator)

                _warnIfSplitInsideNavigationStack(dest.coordinatable)
                dest.setPushType(.push)
                dest.setRouteType(.push)
                dest.coordinatable?.setHasLayerNavigationCoordinatable(true)
                dest.coordinatable?.setParent(coordinator)

                if let flowCoordinator = dest.coordinatable as? any FlowCoordinatable {
                    flowCoordinator.setPresentedAs(.push)
                }

                destinations.append(dest)
            }
            initialPath = []
        }
        self.isSetup = true
    }

    /// Sets the parent coordinator reference.
    public func setParent(_ parent: any Coordinatable) {
        self.parent = parent
    }

    func setAnimation(animation: Animation?) {
        self.animation = animation
    }
}

@MainActor
extension FlowStack {
    func push(destination: Destination) {
        destinations.append(destination)
    }

    func pop() {
        guard !destinations.isEmpty else {
            coordinator?.dismissCoordinator()
            return
        }
        let removed = destinations.removeLast()
        removed.resolveDismissal()
    }

    func pop(count: Int) {
        let removeCount = min(max(count, 0), destinations.count)
        guard removeCount > 0 else { return }
        let removed = Array(destinations.suffix(removeCount))
        destinations.removeLast(removeCount)
        for destination in removed {
            destination.resolveDismissal()
        }
    }

    func popToRoot() {
        let removed = destinations
        destinations.removeAll()
        for destination in removed {
            destination.resolveDismissal()
        }
    }

    func popToFirst(_ destination: Coordinator.Destinations.Meta) -> Destination? {
        if let root = root,
           let rootMeta = root.meta as? Coordinator.Destinations.Meta,
           rootMeta == destination {
            popToRoot()
            return root
        }

        guard let firstIndex = destinations.firstIndex(where: { dest in
            guard let destMeta = dest.meta as? Coordinator.Destinations.Meta else { return false }
            return destMeta == destination
        }) else {
            return nil
        }

        let targetDestination = destinations[firstIndex]

        let newCount = firstIndex + 1
        if destinations.count > newCount {
            let removed = destinations[newCount...]
            destinations.removeSubrange(newCount...)
            for destination in removed {
                destination.resolveDismissal()
            }
        }

        return targetDestination
    }

    func popToLast(_ destination: Coordinator.Destinations.Meta) -> Destination? {
        if let root = root,
           let rootMeta = root.meta as? Coordinator.Destinations.Meta,
           rootMeta == destination {
            popToRoot()
            return root
        }

        guard let lastIndex = destinations.lastIndex(where: { dest in
            guard let destMeta = dest.meta as? Coordinator.Destinations.Meta else { return false }
            return destMeta == destination
        }) else {
            return nil
        }

        let targetDestination = destinations[lastIndex]

        let newCount = lastIndex + 1
        if destinations.count > newCount {
            let removed = destinations[newCount...]
            destinations.removeSubrange(newCount...)
            for destination in removed {
                destination.resolveDismissal()
            }
        }

        return targetDestination
    }

    func setRoot(root: Destination, animation: Animation?) {
         withAnimation(animation ?? self.animation) {
             // Clear pushed destinations before replacing the root.
             // Destinations were pushed relative to the old root and are
             // invalid once the root changes. Clearing them first ensures
             // the NavigationStack path is empty before the root view
             // switches, preventing a stale navigation bar.
             let removedDestinations = destinations
             destinations.removeAll()

             // Pushed destinations and the previous root were torn down
             // because the parent's state changed underneath them — that
             // is a cancellation, not a user-initiated dismissal.
             for destination in removedDestinations {
                 destination.resolveDismissal()
             }
             self.root?.resolveDismissal()

             var mutableRoot = root
             _warnIfSplitInsideNavigationStack(mutableRoot.coordinatable)
             mutableRoot.coordinatable?.setHasLayerNavigationCoordinatable(true)

             if let coordinator {
                 mutableRoot.coordinatable?.setParent(coordinator)
             }

             if let presentedAs = presentedAs, mutableRoot.pushType == nil {
                 mutableRoot.setPushType(presentedAs)
             }

             self.root = mutableRoot
         }
     }
}
