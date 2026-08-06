//
//  HierarchyQueries.swift
//  ScaffoldingTesting
//

import Scaffolding

@MainActor
public extension Coordinatable {
    /// Every already-created coordinator of the given type below this one, in
    /// tree order.
    ///
    /// Walks the same snapshot ``Coordinatable/debugHierarchy()`` renders, so
    /// it never materialises a coordinator that does not exist yet.
    func descendants<T: Coordinatable>(ofType type: T.Type = T.self) -> [T] {
        hierarchySnapshot().flatMap { $0.coordinators(ofType: type) }
    }

    /// The first already-created coordinator of the given type below this one.
    ///
    /// The typed handle a test needs when the navigation that created the
    /// child happened inside the code under test — for example an
    /// `await present(_:awaiting:)` call, which hands back no coordinator:
    ///
    /// ```swift
    /// let picking = Task { await favorites.addPlanet() }
    /// await waitUntil { favorites.isPresentingModal }
    ///
    /// favorites.descendant(ofType: PlanetPickerCoordinator.self)?.pick("Mars")
    /// await picking.value
    /// ```
    ///
    /// This is for tests and debug tooling. Production code should stay with
    /// the `expecting:` overloads or the typed trailing closures, which hand
    /// the child over at the moment the route lands.
    func descendant<T: Coordinatable>(ofType type: T.Type = T.self) -> T? {
        descendants(ofType: type).first
    }

    /// Whether the tree below this coordinator contains the given
    /// destination, in any role.
    ///
    /// The typed replacement for matching ``Coordinatable/debugHierarchy()``
    /// output:
    ///
    /// ```swift
    /// #expect(app.hierarchyContains(PlanetsCoordinator.self, .detail))
    /// ```
    ///
    /// - Parameters:
    ///   - coordinatorType: The coordinator that owns the destination — it
    ///     scopes `meta`, so the case can be written as a leading dot.
    ///   - meta: The destination case to look for.
    func hierarchyContains<C: Coordinatable>(
        _ coordinatorType: C.Type,
        _ meta: C.Destinations.Meta
    ) -> Bool {
        hierarchySnapshot().contains { $0.contains(meta, role: nil) }
    }

    /// Whether the tree below this coordinator contains the given destination
    /// **in a specific role**.
    ///
    /// ```swift
    /// #expect(app.hierarchyContains(PlanetsCoordinator.self, .detail, as: .push))
    /// #expect(app.hierarchyContains(AppCoordinator.self, .planets, as: .tab(index: 0, isSelected: true)))
    /// ```
    ///
    /// - Parameters:
    ///   - coordinatorType: The coordinator that owns the destination.
    ///   - meta: The destination case to look for.
    ///   - role: The role it must have — `.root`, `.push`, `.sheet`,
    ///     `.fullScreenCover`, or `.tab(index:isSelected:)`.
    func hierarchyContains<C: Coordinatable>(
        _ coordinatorType: C.Type,
        _ meta: C.Destinations.Meta,
        as role: HierarchyRole
    ) -> Bool {
        hierarchySnapshot().contains { $0.contains(meta, role: role) }
    }
}

@MainActor
private extension HierarchyNode {
    func coordinators<T: Coordinatable>(ofType type: T.Type) -> [T] {
        var found: [T] = []
        if let match = coordinator as? T { found.append(match) }
        found += children.flatMap { $0.coordinators(ofType: type) }
        return found
    }

    func contains<M: DestinationMeta>(_ target: M, role: HierarchyRole?) -> Bool {
        if (meta as? M) == target, role == nil || role == self.role {
            return true
        }
        return children.contains { $0.contains(target, role: role) }
    }
}
