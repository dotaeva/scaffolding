import SwiftUI

/// Detaches every removed branch before delivering callbacks, deepest and
/// topmost first. Inspection and teardown never initialize dormant containers.
@MainActor
func resolveDismissals(_ destinations: [Destination]) {
    var resolutions: [Destination.ResolutionState] = []
    var visited = Set<ObjectIdentifier>()

    func collect(_ destination: Destination, structural: Bool = false) {
        guard structural || !destination.resolution.didResolve else { return }
        resolutions.append(destination.resolution)
        guard let child = destination.materializedCoordinatable else { return }

        // A route may return an existing coordinator. Replacing its owning
        // destination must not tear down that same instance's new attachment.
        if !structural, let current = child._owningDestination(), current.id != destination.id {
            return
        }
        guard visited.insert(ObjectIdentifier(child)).inserted else { return }

        if let flow = child as? any FlowCoordinatable {
            let stack = flow._stack
            let removed = stack.destinations
            stack.destinations = []
            if !structural { stack.parent = nil }
            if let root = stack.root { collect(root, structural: true) }
            for route in removed { collect(route) }
        } else if let root = child as? any RootCoordinatable {
            let container = root._root
            let removed = container.modals
            container.modals = []
            if !structural { container.parent = nil }
            if let route = container.root { collect(route, structural: true) }
            for route in removed { collect(route) }
        } else if let tabs = child as? any TabCoordinatable {
            let container = tabs._tabItems
            let removed = container.modals
            container.modals = []
            if !structural { container.parent = nil }
            for tab in container.tabs { collect(tab, structural: true) }
            for route in removed { collect(route) }
        } else if let split = child as? any SplitCoordinatable {
            let container = split._columns
            let removed = container.modals
            container.modals = []
            if !structural { container.parent = nil }
            for column in [container.sidebar, container.content, container.detail].compactMap({ $0 }) {
                collect(column, structural: true)
            }
            for route in removed { collect(route) }
        }
    }

    for destination in destinations { collect(destination) }
    for resolution in resolutions.reversed() { resolution.resolve() }
}
