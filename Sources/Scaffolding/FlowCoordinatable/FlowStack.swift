//
//  FlowStack.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A type-erased, read-only view of a ``FlowStack``.
///
/// Change navigation through the owning coordinator's methods.
@MainActor
public protocol AnyFlowStack: AnyObject, CoordinatableData where Coordinator: FlowCoordinatable {
    /// The flow's root destination.
    var root: Destination? { get }
    /// The pushed and presented entries above the root, bottom first.
    var destinations: [Destination] { get }
    /// The default animation for this flow's navigation changes.
    var animation: Animation? { get }
    /// The presentation this flow inherits from its host: `.push`, `.sheet`,
    /// or `.fullScreenCover`, or `nil` when no host pushes or presents it.
    var presentedAs: PresentationType? { get }
}

/// The observable navigation state of a ``FlowCoordinatable``.
///
/// Holds the root and the pushed and presented entries above it. Seed it with
/// an initializer; change it through the coordinator's methods.
///
/// ```swift
/// var stack = FlowStack<HomeCoordinator>(root: .home)
/// ```
@MainActor
@Observable
public class FlowStack<Coordinator: FlowCoordinatable>: AnyFlowStack {
    /// The destination at the bottom of the stack.
    public internal(set) var root: Destination?
    /// The coordinator hosting this flow, or `nil` at the top level.
    public internal(set) weak var parent: (any Coordinatable)?
    /// Whether this flow renders in an enclosing flow's `NavigationStack`
    /// instead of its own, as when it is pushed.
    public internal(set) var hasLayerNavigationCoordinator: Bool = false
    /// The default animation for root changes, pushes, pops, and modal changes.
    public internal(set) var animation: Animation? = .default
    /// The presentation this flow inherits from its host: `.push`, `.sheet`,
    /// or `.fullScreenCover`, or `nil` when no host pushes or presents it.
    public internal(set) var presentedAs: PresentationType?

    /// The pushed and presented entries above the root, bottom first.
    public internal(set) var destinations: [Destination] = .init()

    /// Whether the initial root and path have been resolved.
    public internal(set) var isSetup: Bool = false
    private var initialRoot: Coordinator.Destinations?
    private var initialPath: [Coordinator.Destinations] = []
    private weak var coordinator: Coordinator?

    /// Creates a stack that shows a root.
    ///
    /// - Parameter root: The root case.
    public init(root: Coordinator.Destinations) {
        self.initialRoot = root
    }

    /// Creates a stack with a root and screens already pushed above it.
    ///
    /// Use it to seed a preview, a test, or a deep entry point. The path is
    /// built on first use. Pushes unavailable on the current OS are skipped;
    /// the root must be available.
    ///
    /// ```swift
    /// var stack = FlowStack<HomeCoordinator>(root: .home, pushing: [.detail(id: 42)])
    /// ```
    ///
    /// - Parameters:
    ///   - root: The root case.
    ///   - path: Cases to push above the root, bottom first.
    public init(root: Coordinator.Destinations, pushing path: [Coordinator.Destinations]) {
        self.initialRoot = root
        self.initialPath = path
    }

    /// Resolves the initial root and path once. The framework calls this.
    ///
    /// - Parameter coordinator: The coordinator that owns the stack.
    public func setup(for coordinator: Coordinator) {
        guard !isSetup else { return }
        isSetup = true
        self.coordinator = coordinator
        if let rootDestination = initialRoot, root == nil {
            var rootDest = rootDestination.resolvedValue(for: coordinator)

            _warnIfSplitInsideNavigationStack(rootDest.coordinatable)
            rootDest.coordinatable?.attach(to: coordinator, navigationLayer: true, presentation: presentedAs)

            if let presentedAs = presentedAs {
                rootDest.setPushType(presentedAs)
            }

            root = rootDest
            self.initialRoot = nil
        }
        if !initialPath.isEmpty {
            for element in initialPath where element.isAvailable {
                var dest = element.resolvedValue(for: coordinator)

                _warnIfSplitInsideNavigationStack(dest.coordinatable)
                dest.setPushType(.push)
                dest.setRouteType(.push)
                dest.coordinatable?.attach(to: coordinator, navigationLayer: true, presentation: .push)

                destinations.append(dest)
            }
            initialPath = []
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

@MainActor
extension FlowStack {
    func push(destination: Destination) {
        // A path change with no transaction is applied without animation by
        // NavigationStack on macOS, so the push snapped there while iOS
        // animated it either way. Carrying the stack's animation makes the
        // same call behave the same on both.
        withScaffoldingAnimation(animation) {
            destinations.append(destination)
        }
    }

    func pop() {
        guard !destinations.isEmpty else {
            coordinator?.dismissCoordinator()
            return
        }
        let removed = withScaffoldingAnimation(animation) { destinations.removeLast() }
        removed.resolveDismissal()
    }

    func pop(count: Int) {
        let removeCount = min(max(count, 0), destinations.count)
        guard removeCount > 0 else { return }
        let removed = Array(destinations.suffix(removeCount))
        withScaffoldingAnimation(animation) {
            destinations.removeLast(removeCount)
        }
        resolveDismissals(removed)
    }

    func popToRoot() {
        let removed = destinations
        withScaffoldingAnimation(animation) {
            destinations.removeAll()
        }
        resolveDismissals(removed)
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
            let removed = Array(destinations[newCount...])
            withScaffoldingAnimation(animation) {
                destinations.removeSubrange(newCount...)
            }
            resolveDismissals(removed)
        }

        return targetDestination
    }

    func popToLast(_ destination: Coordinator.Destinations.Meta) -> Destination? {
        guard let lastIndex = destinations.lastIndex(where: { dest in
            guard let destMeta = dest.meta as? Coordinator.Destinations.Meta else { return false }
            return destMeta == destination
        }) else {
            if let root, let rootMeta = root.meta as? Coordinator.Destinations.Meta,
               rootMeta == destination {
                popToRoot()
                return root
            }
            return nil
        }

        let targetDestination = destinations[lastIndex]

        let newCount = lastIndex + 1
        if destinations.count > newCount {
            let removed = Array(destinations[newCount...])
            withScaffoldingAnimation(animation) {
                destinations.removeSubrange(newCount...)
            }
            resolveDismissals(removed)
        }

        return targetDestination
    }

    func setRoot(root: Destination, animation: Animation?) {
        let removed = [self.root].compactMap { $0 } + destinations
        withScaffoldingAnimation(animation ?? self.animation) {
            destinations.removeAll()
            var mutableRoot = root
            _warnIfSplitInsideNavigationStack(mutableRoot.coordinatable)
            if let coordinator {
                mutableRoot.coordinatable?.attach(to: coordinator, navigationLayer: true, presentation: presentedAs)
            }
            if let presentedAs, mutableRoot.pushType == nil {
                mutableRoot.setPushType(presentedAs)
            }
            self.root = mutableRoot
        }
        resolveDismissals(removed)
    }
}

@MainActor
protocol _MutableFlowStack: AnyFlowStack, _MutableCoordinatableData {
    var root: Destination? { get set }
    var destinations: [Destination] { get set }
    var animation: Animation? { get set }
    var presentedAs: PresentationType? { get set }
}

extension FlowStack: _MutableFlowStack {}
