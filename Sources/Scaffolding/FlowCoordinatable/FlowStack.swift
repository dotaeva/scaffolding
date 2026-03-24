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
    private var coordinator: Coordinator?

    /// Creates a new flow stack with the given initial root destination.
    ///
    /// - Parameter root: The destination case to display as the root.
    public init(root: Coordinator.Destinations) {
        self.initialRoot = root
    }

    /// Performs one-time setup, resolving the initial root destination.
    ///
    /// - Parameter coordinator: The coordinator that owns this stack.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        self.coordinator = coordinator
        if let rootDestination = initialRoot, root == nil {
            var rootDest = rootDestination.value(for: coordinator)

            rootDest.coordinatable?.setHasLayerNavigationCoordinatable(true)
            rootDest.coordinatable?.setParent(coordinator)

            if let presentedAs = presentedAs {
                rootDest.setPushType(presentedAs)
            }

            root = rootDest
            self.initialRoot = nil
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
        destinations.removeLast()
    }

    func popToRoot() {
        destinations.removeAll()
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
            destinations.removeSubrange(newCount...)
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
            destinations.removeSubrange(newCount...)
        }

        return targetDestination
    }

    func setRoot(root: Destination, animation: Animation?) {
         withAnimation(animation ?? self.animation) {
             var mutableRoot = root
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
