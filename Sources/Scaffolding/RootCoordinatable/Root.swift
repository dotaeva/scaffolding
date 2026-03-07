//
//  Root.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A type-erased protocol for ``Root`` that allows the framework to
/// manipulate root state without knowing the concrete coordinator type.
@MainActor
public protocol AnyRoot: AnyObject, CoordinatableData where Coordinator: RootCoordinatable {
    /// The current root destination.
    var root: Destination? { get set }
    /// The default animation applied to root transitions.
    var animation: Animation? { get set }
    /// The presentation type if this root coordinator was presented modally.
    var presentedAs: PresentationType? { get set }
}

/// Observable state container for a ``RootCoordinatable`` coordinator.
///
/// `Root` holds a single destination that represents the current screen.
/// Calling ``RootCoordinatable/setRoot(_:animation:)`` swaps this value
/// atomically, optionally with an animation.
///
/// ```swift
/// var root = Root<AppCoordinator>(root: .login)
/// ```
@MainActor
@Observable
public class Root<Coordinator: RootCoordinatable>: AnyRoot {
    /// The current root destination.
    public var root: Destination?
    /// The parent coordinator, if any.
    public var parent: (any Coordinatable)?
    /// Whether a parent flow coordinator provides the navigation layer.
    public var hasLayerNavigationCoordinator: Bool = false
    /// The default animation used for root transitions.
    public var animation: Animation? = .default
    /// The presentation type when this coordinator was presented modally.
    public var presentedAs: PresentationType?

    /// Whether ``setup(for:)`` has been called.
    public var isSetup: Bool = false
    private var initialRoot: Coordinator.Destinations?

    /// Creates a new root container with the given initial destination.
    ///
    /// - Parameter root: The destination case to display initially.
    public init(root: Coordinator.Destinations) {
        self.initialRoot = root
    }

    /// Performs one-time setup, resolving the initial root destination.
    ///
    /// - Parameter coordinator: The coordinator that owns this container.
    public func setup(for coordinator: Coordinator) {
            guard !isSetup else { return }
            if let rootDestination = initialRoot, root == nil {
                var rootDest = rootDestination.value(for: coordinator)

                rootDest.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinator)

                if let presentedAs = presentedAs {
                    rootDest.setPushType(presentedAs)
                    if let flowCoordinator = rootDest.coordinatable as? any FlowCoordinatable {
                        flowCoordinator.setPresentedAs(presentedAs)
                    } else if let tabCoordinator = rootDest.coordinatable as? any TabCoordinatable {
                        tabCoordinator.setPresentedAs(presentedAs)
                    } else if let rootCoordinator = rootDest.coordinatable as? any RootCoordinatable {
                        rootCoordinator.setPresentedAs(presentedAs)
                    }
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

extension Root {
    func setRoot(root: Destination, animation: Animation?) {
        withAnimation(animation ?? self.animation) {
            root.coordinatable?.setHasLayerNavigationCoordinatable(self.hasLayerNavigationCoordinator)
            self.root = root
        }
    }
}
