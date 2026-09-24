import SwiftUI

@MainActor
extension Coordinatable {
    /// Attaches a child without materializing any of its dormant destinations.
    /// Existing structural children adopt the new host's navigation context.
    func attach(to owner: any Coordinatable, navigationLayer: Bool, presentation: PresentationType?) {
        setParent(owner)
        updateNavigationContext(navigationLayer: navigationLayer, presentation: presentation)
    }

    var inheritedPresentation: PresentationType? {
        if let flow = self as? any FlowCoordinatable { return flow._stack.presentedAs }
        if let root = self as? any RootCoordinatable { return root._root.presentedAs }
        if let tabs = self as? any TabCoordinatable { return tabs._tabItems.presentedAs }
        if let split = self as? any SplitCoordinatable { return split._columns.presentedAs }
        return nil
    }

    func inheritPresentation(_ type: PresentationType) {
        updateNavigationContext(navigationLayer: hasLayerNavigationCoordinatable, presentation: type)
    }

    func updateNavigationContext(navigationLayer: Bool, presentation: PresentationType?) {
        var visited = Set<ObjectIdentifier>()

        func refresh(_ original: Destination?, layer: Bool) -> Destination? {
            guard var destination = original else { return nil }
            destination.renewDismissalIfResolved()
            destination.pushType = presentation
            if let child = destination.materializedCoordinatable {
                visit(child, layer: layer)
            }
            return destination
        }

        func visit(_ coordinator: any Coordinatable, layer: Bool) {
            guard visited.insert(ObjectIdentifier(coordinator)).inserted else { return }
            if let flow = coordinator as? any FlowCoordinatable {
                let storage = flow._stack
                storage.hasLayerNavigationCoordinator = layer
                storage.presentedAs = presentation
                // A flow provides the navigation layer to its structural root
                // whether it owns the native stack or shares an ancestor's.
                storage.root = refresh(storage.root, layer: true)
            } else if let root = coordinator as? any RootCoordinatable {
                let storage = root._root
                storage.hasLayerNavigationCoordinator = layer
                storage.presentedAs = presentation
                storage.root = refresh(storage.root, layer: layer)
            } else if let tabs = coordinator as? any TabCoordinatable {
                let storage = tabs._tabItems
                storage.hasLayerNavigationCoordinator = layer
                storage.presentedAs = presentation
                storage.tabs = storage.tabs.compactMap { refresh($0, layer: layer) }
            } else if let split = coordinator as? any SplitCoordinatable {
                let storage = split._columns
                storage.hasLayerNavigationCoordinator = layer
                storage.presentedAs = presentation
                storage.sidebar = refresh(storage.sidebar, layer: false)
                storage.content = refresh(storage.content, layer: false)
                storage.detail = refresh(storage.detail, layer: false)
            }
        }
        visit(self, layer: navigationLayer)
    }
}
