//
//  Activation.swift
//  ScaffoldingTesting
//

import Scaffolding

@MainActor
public extension Coordinatable {
    /// Resolves the coordinator's initial destinations and returns it, ready
    /// to assert on.
    ///
    /// Flow, root, tab, and split containers resolve initial destinations lazily.
    /// Rendering and navigation can trigger setup; tests need not render.
    /// Navigation queries such as `topDestination` and
    /// `isRoot(_:)` also resolve their own container. Hierarchy inspection
    /// deliberately does not; use this helper to initialize the descendant
    /// tree before calling `debugHierarchy()` or performing deep queries.
    ///
    /// ```swift
    /// let home = HomeCoordinator().activated()
    ///
    /// #expect(home.topDestination == .home)
    /// ```
    ///
    /// Nothing is rendered: the coordinator's view value is created and
    /// discarded for this coordinator and its resolved descendants. Calling
    /// it more than once is harmless — setup runs once per coordinator.
    @discardableResult
    func activated() -> Self {
        var visited = Set<ObjectIdentifier>()
        func activate(_ coordinator: any Coordinatable) {
            guard visited.insert(ObjectIdentifier(coordinator)).inserted else { return }
            _ = coordinator.view
            for node in coordinator.hierarchySnapshot() {
                if let child = node.coordinator { activate(child) }
            }
        }
        activate(self)
        return self
    }
}
