//
//  Root.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A read-only, type-erased view of a ``Root`` container.
///
/// Change navigation through the owning coordinator's methods.
@MainActor
public protocol AnyRoot: AnyObject, CoordinatableData where Coordinator: RootCoordinatable {
    /// The current root destination.
    var root: Destination? { get }
    /// The default animation for root swaps and modal presentations.
    var animation: Animation? { get }
    /// How the nearest host presents this coordinator, or `nil` when no host
    /// pushes or presents it.
    var presentedAs: PresentationType? { get }
    /// This coordinator's modal requests in order; the first is visible.
    var modals: [Destination] { get }
}

/// The state container for a ``RootCoordinatable``: one root destination
/// and the coordinator's modal requests.
///
/// Seed it with the initial case and change it through the coordinator:
///
/// ```swift
/// var root = Root<AppCoordinator>(root: .login)
/// ```
///
/// ``RootCoordinatable/setRoot(_:animation:)`` replaces the root. Modals
/// stay until dismissed.
@MainActor
@Observable
public class Root<Coordinator: RootCoordinatable>: AnyRoot {
    /// The current root destination.
    public internal(set) var root: Destination?
    /// The coordinator hosting this one, or `nil` at the top of the tree.
    public internal(set) weak var parent: (any Coordinatable)?
    /// Whether an enclosing flow provides the navigation stack.
    public internal(set) var hasLayerNavigationCoordinator: Bool = false
    /// The default animation for root swaps and modal presentations.
    ///
    /// `.default` until changed with ``RootCoordinatable/setTransitionAnimation(_:)``.
    public internal(set) var animation: Animation? = .default
    /// How the nearest host presents this coordinator, or `nil` when no host
    /// pushes or presents it.
    public internal(set) var presentedAs: PresentationType?
    /// This coordinator's modal requests in order; the first is visible.
    public internal(set) var modals: [Destination] = []

    /// Whether the initial root has been resolved.
    public internal(set) var isSetup: Bool = false
    private var initialRoot: Coordinator.Destinations?
    private weak var coordinator: Coordinator?
    
    /// Creates a container that shows `root` first.
    ///
    /// The destination is built on first render, navigation, or query.
    ///
    /// - Parameter root: The initial root case.
    public init(root: Coordinator.Destinations) {
        self.initialRoot = root
    }
    
    /// Resolves the initial root for the owning coordinator.
    ///
    /// The framework calls this. Later calls do nothing.
    ///
    /// - Parameter coordinator: The owning coordinator.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        isSetup = true
        self.coordinator = coordinator
        if let rootDestination = initialRoot, root == nil {
            var rootDest = rootDestination.resolvedValue(for: coordinator)
            
            rootDest.coordinatable?.attach(to: coordinator, navigationLayer: hasLayerNavigationCoordinator, presentation: presentedAs)
            rootDest.pushType = presentedAs

            root = rootDest
            self.initialRoot = nil
        }
    }
    
    /// Sets the hosting coordinator. The framework calls this.
    public func setParent(_ parent: any Coordinatable) {
        self.parent = parent
    }
    
    func setAnimation(animation: Animation?) {
        self.animation = animation
    }
}

extension Root {
    func setRoot(root: Destination, animation: Animation?) {
        let previous = self.root
        withScaffoldingAnimation(animation ?? self.animation) {
            var mutableRoot = root
            if let coordinator {
                mutableRoot.coordinatable?.attach(to: coordinator, navigationLayer: hasLayerNavigationCoordinator, presentation: presentedAs)
            }
            mutableRoot.pushType = presentedAs

            self.root = mutableRoot
        }
        previous?.resolveDismissal()
    }
}

@MainActor
protocol _MutableRoot: AnyRoot, _MutableCoordinatableData {
    var root: Destination? { get set }
    var animation: Animation? { get set }
    var presentedAs: PresentationType? { get set }
    var modals: [Destination] { get set }
}

extension Root: _MutableRoot {}
