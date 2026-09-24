//
//  CoordinatableView.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 29.09.2025.
//

import SwiftUI

/// A view that renders a coordinator.
///
/// ``FlowCoordinatableView``, ``RootCoordinatableView``,
/// ``TabCoordinatableView``, and ``SplitCoordinatableView`` conform. Get one
/// from ``Coordinatable/view``; you don't create them yourself.
@MainActor
public protocol CoordinatableView: View {
    /// The coordinator this view renders.
    var coordinator: any Coordinatable { get }
}

@MainActor
public extension CoordinatableView {
    /// Renders a destination's view or child coordinator, with its owner
    /// injected into the environment.
    ///
    /// When the owner is another coordinator, such as a pushed child flow
    /// sharing this stack, the owner's `customize(_:)` wraps the result.
    /// Framework use.
    @ViewBuilder
    func wrappedView(_ destination: Destination) -> some View {
        let content = Group {
            if let view = destination.view, let parent = destination.parent {
                AnyView(view.environmentCoordinatable(parent))
            } else if let c = destination.coordinatable {
                AnyView(c.view)
            } else {
                AnyView(EmptyView())
            }
        }

        if let parent = destination.parent, parent._dataId != coordinator._dataId {
            AnyView(parent.customizeErased(AnyView(content)))
        } else {
            AnyView(content)
        }
    }
}
