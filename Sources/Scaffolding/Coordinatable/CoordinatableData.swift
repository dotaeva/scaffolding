//
//  CoordinatableData.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftUI

/// A shared interface for the observable state containers that back each
/// coordinator type.
///
/// ``FlowStack``, ``TabItems``, and ``Root`` all conform to
/// `CoordinatableData`. The protocol provides parent tracking, lazy setup,
/// and identity so that SwiftUI can diff coordinator hierarchies
/// efficiently.
@MainActor
public protocol CoordinatableData: Identifiable {
    associatedtype Coordinator: Coordinatable

    /// The parent coordinator that owns this coordinator, if any.
    var parent: (any Coordinatable)? { get set }

    /// Whether a parent ``FlowCoordinatable`` provides the
    /// `NavigationStack` layer.
    var hasLayerNavigationCoordinator: Bool { get set }

    /// Assigns the parent coordinator reference.
    func setParent(_ parent: any Coordinatable) -> Void

    /// Whether ``setup(for:)`` has already been called.
    var isSetup: Bool { get set }

    /// Performs one-time initialization using the owning coordinator.
    func setup(for coordinator: Coordinator) -> Void
}
