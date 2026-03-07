//
//  CoordinatableView.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 29.09.2025.
//

import SwiftUI

/// A SwiftUI view that is associated with a specific coordinator.
///
/// ``FlowCoordinatableView``, ``TabCoordinatableView``, and
/// ``RootCoordinatableView`` all conform to this protocol. It provides
/// the ``wrappedView(_:)`` helper used internally to resolve a
/// ``Destination`` into its final SwiftUI view tree.
@MainActor
public protocol CoordinatableView: View {
    /// The coordinator this view belongs to.
    var coordinator: any Coordinatable { get }
}

@MainActor
public extension CoordinatableView {
    /// Resolves a ``Destination`` into its SwiftUI view, injecting the
    /// coordinator into the environment and applying any `customize(_:)`
    /// wrapper defined on the destination's parent.
    @ViewBuilder
    func wrappedView(_ destination: Destination) -> some View {
        let content = Group {
            if let view = destination.view {
                AnyView(view.environmentCoordinatable(destination.parent))
            } else if let c = destination.coordinatable {
                AnyView(c.view())
            } else {
                AnyView(EmptyView())
            }
        }

        if destination.parent._dataId != coordinator._dataId {
            AnyView(destination.parent.customizeErased(AnyView(content)))
        } else {
            AnyView(content)
        }
    }
}
