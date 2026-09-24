//
//  CoordinatableData.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI

/// The shared interface of the coordinator state containers.
///
/// ``FlowStack``, ``Root``, ``TabItems``, and ``SplitColumns`` conform. Read a
/// container's state freely; change it only through coordinator methods. The
/// requirements below are framework plumbing.
@MainActor
public protocol CoordinatableData: Identifiable {
    /// The coordinator that owns this container.
    associatedtype Coordinator: Coordinatable

    /// The host of the owning coordinator, or `nil` at the top level.
    var parent: (any Coordinatable)? { get }

    /// Whether the owning coordinator renders inside a `NavigationStack`
    /// owned by an ancestor flow.
    var hasLayerNavigationCoordinator: Bool { get }

    /// Attaches the owning coordinator to its host. Framework use only.
    func setParent(_ parent: any Coordinatable) -> Void

    /// Whether ``setup(for:)`` has run.
    var isSetup: Bool { get }

    /// Resolves the container's initial destinations for its coordinator.
    /// Navigation and rendering call it on demand.
    func setup(for coordinator: Coordinator) -> Void
}

@MainActor
protocol _MutableCoordinatableData: AnyObject, CoordinatableData {
    var parent: (any Coordinatable)? { get set }
    var hasLayerNavigationCoordinator: Bool { get set }
    var isSetup: Bool { get set }
}
