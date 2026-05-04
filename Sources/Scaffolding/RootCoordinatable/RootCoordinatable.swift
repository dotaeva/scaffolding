//
//  RootCoordinatable.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI
import Observation

/// A coordinator that performs atomic root switches.
///
/// Conform to `RootCoordinatable` to build flows where the entire screen
/// content is swapped at once — for example, switching between
/// authentication and main-app coordinators. Provide a ``Root`` property
/// and define destination functions using the ``Scaffoldable(injectsCoordinator:)`` macro.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class AppCoordinator: @MainActor RootCoordinatable {
///     var root = Root<AppCoordinator>(root: .login)
///
///     func login() -> any Coordinatable { LoginCoordinator() }
///     func main() -> any Coordinatable { MainTabCoordinator() }
/// }
/// ```
@MainActor
public protocol RootCoordinatable: Coordinatable where ViewType == RootCoordinatableView {
    /// The observable container that holds the current root destination.
    var root: Root<Self> { get }

    /// A type-erased accessor for the root container.
    var anyRoot: any AnyRoot { get }
}

@MainActor
public extension RootCoordinatable {
    var _dataId: ObjectIdentifier {
        root.id
    }

    var anyRoot: any AnyRoot {
        root.setup(for: self)
        return root
    }

    var view: RootCoordinatableView {
        root.setup(for: self)
        return .init(coordinator: self)
    }

    var parent: (any Coordinatable)? {
        root.parent
    }

    var hasLayerNavigationCoordinatable: Bool {
        root.hasLayerNavigationCoordinator
    }

    func setHasLayerNavigationCoordinatable(_ value: Bool) {
        root.hasLayerNavigationCoordinator = value
    }

    func setParent(_ parent: any Coordinatable) {
        root.setParent(parent)
    }

    /// Sets the default animation used for root transitions.
    func setRootTransitionAnimation(_ animation: Animation?) {
        root.setAnimation(animation: animation)
    }
}

@MainActor
public extension RootCoordinatable {
    /// Switches the root destination.
    ///
    /// - Parameters:
    ///   - destination: The new root destination.
    ///   - animation: An optional animation override. When `nil` the
    ///     container's default animation is used.
    /// - Returns: `self` for chaining.
    @discardableResult
    func setRoot(_ destination: Destinations, animation: Animation? = nil) -> Self {
        let dest = destination.value(for: self)

        dest.coordinatable?.setParent(self)
        root.setRoot(root: dest, animation: animation)

        return self
    }

    /// Returns whether the current root matches the given destination.
    func isRoot(_ destination: Destinations.Meta) -> Bool {
        guard let rootMeta = root.root?.meta as? Self.Destinations.Meta else { return false }
        return rootMeta == destination
    }

    /// Switches the root and invokes a typed callback with the resolved
    /// child coordinator.
    @discardableResult
    func setRoot<T: Coordinatable>(
        _ destination: Destinations,
        animation: Animation? = nil,
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let dest = destination.value(for: self)
        dest.coordinatable?.setParent(self)
        root.setRoot(root: dest, animation: animation)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

@MainActor
public extension RootCoordinatable {
    /// Presents a destination modally on this root coordinator.
    ///
    /// The modal lives on this coordinator's container and is rendered
    /// as a sheet or full-screen cover by the root's view layer.
    ///
    /// - Parameters:
    ///   - destination: The destination to present.
    ///   - type: The modal presentation style. Defaults to `.sheet`.
    ///   - onDismiss: A closure invoked when the modal is dismissed.
    /// - Returns: `self` for chaining.
    @discardableResult
    func present(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        onDismiss: @escaping @MainActor () -> Void = { }
    ) -> Self {
        _ = performPresent(destination, as: type, onDismiss: onDismiss)
        return self
    }

    /// Presents a destination modally and invokes a typed callback with the
    /// resolved child coordinator.
    ///
    /// The callback fires once after the modal lands on the root, receiving
    /// the newly created coordinator cast to `T`. If the destination does
    /// not resolve to a coordinator of type `T`, the callback is not
    /// invoked.
    @discardableResult
    func present<T: Coordinatable>(
        _ destination: Destinations,
        as type: ModalPresentationType = .sheet,
        onDismiss: @escaping @MainActor () -> Void = { },
        _ action: @escaping @MainActor (T) -> Void
    ) -> Self {
        let dest = performPresent(destination, as: type, onDismiss: onDismiss)
        if let coordinator = dest.coordinatable as? T {
            action(coordinator)
        }
        return self
    }
}

@MainActor
private extension RootCoordinatable {
    @discardableResult
    func performPresent(
        _ destination: Destinations,
        as type: ModalPresentationType,
        onDismiss: @escaping @MainActor () -> Void
    ) -> Destination {
        var dest = destination.value(for: self)
        dest.setOnDismiss(onDismiss)
        dest.setPushType(type.presentationType)
        dest.setRouteType(DestinationType.from(presentationType: type.presentationType))
        dest.coordinatable?.setHasLayerNavigationCoordinatable(false)
        dest.coordinatable?.setParent(self)

        if let flowCoordinator = dest.coordinatable as? any FlowCoordinatable {
            flowCoordinator.setPresentedAs(type.presentationType)
        } else if let tabCoordinator = dest.coordinatable as? any TabCoordinatable {
            tabCoordinator.setPresentedAs(type.presentationType)
        } else if let rootCoordinator = dest.coordinatable as? any RootCoordinatable {
            rootCoordinator.setPresentedAs(type.presentationType)
        }

        anyRoot.modals.append(dest)
        return dest
    }
}

@MainActor
public extension RootCoordinatable {
    func setPresentedAs(_ type: PresentationType) {
        anyRoot.presentedAs = type
        if var root = anyRoot.root, root.pushType == nil {
            root.setPushType(type)
            anyRoot.root = root
        }
    }
}

/// The SwiftUI view generated by a ``RootCoordinatable`` coordinator.
///
/// You never create this view directly — access ``Coordinatable/view``
/// on a `RootCoordinatable` coordinator to obtain it.
public struct RootCoordinatableView: CoordinatableView {
    private let _coordinator: any RootCoordinatable

    public var coordinator: any Coordinatable {
        _coordinator
    }

    init(coordinator: any RootCoordinatable) {
        self._coordinator = coordinator
    }

    @ViewBuilder
    func coordinatableView() -> some View {
        if let root = _coordinator.anyRoot.root {
            wrappedView(root)
                .environmentCoordinatable(coordinator)
                .id(_coordinator.anyRoot.root?.id)
        } else {
            EmptyView()
        }
    }

    private func modals(of type: ModalPresentationType) -> [Destination] {
        let target = type.presentationType
        return _coordinator.anyRoot.modals.filter { $0.pushType == target }
    }

    public var body: some View {
        coordinator.customize(
            AnyView(
                coordinatableView()
            )
        )
        .applyContainerModals(
            sheets: modals(of: .sheet),
            fullScreenCovers: modals(of: .fullScreenCover),
            onDismissSheet: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .sheet) },
            onDismissFullScreenCover: { id in (_coordinator as any Coordinatable).removeContainerModal(id: id, type: .fullScreenCover) },
            modalContent: wrappedView
        )
        .environmentCoordinatable(coordinator)
    }
}
