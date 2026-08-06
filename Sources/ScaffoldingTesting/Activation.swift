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
    /// `FlowStack`, `Root`, and `TabItems` resolve their initial destinations
    /// lazily — the first time the framework touches `view`, `anyStack`,
    /// `anyRoot`, or `anyTabItems`, which at runtime is the first render. A
    /// test renders nothing, so without this the root is still unresolved and
    /// root-dependent reads (`topDestination`, `isRoot(_:)`,
    /// `debugHierarchy()`) come back empty.
    ///
    /// ```swift
    /// let home = HomeCoordinator().activated()
    ///
    /// #expect(home.topDestination == .home)
    /// ```
    ///
    /// Nothing is rendered: the coordinator's view value is created and
    /// discarded. Calling it more than once is harmless — setup runs once.
    @discardableResult
    func activated() -> Self {
        _ = view
        return self
    }
}
