//
//  Waiting.swift
//  ScaffoldingTesting
//

import Testing

/// Spins the main actor until `condition` holds, then returns.
///
/// Navigation itself is synchronous, so this is only needed for the awaitable
/// API — `routeAndWait(to:)`, `presentAndWait(_:as:)`,
/// `present(_:as:awaiting:)` — or for coordinator methods that wrap them in a
/// `Task`. Yielding gives that task a chance to run before the test asserts.
///
/// ```swift
/// let picking = Task { await favorites.addPlanet() }
/// await waitUntil { favorites.isPresentingModal }
///
/// favorites.dismissModal()
/// #expect(await picking.value == nil)
/// ```
///
/// Records an issue at the call site if the condition never holds, rather than
/// hanging the suite.
///
/// - Parameters:
///   - condition: Evaluated on the main actor after every yield.
///   - iterations: How many yields to spend waiting. The default is generous
///     for main-actor work; raise it only if the code under test awaits
///     something slower than navigation.
///   - comment: Shown with the recorded issue on timeout.
@MainActor
public func waitUntil(
    _ condition: @MainActor () -> Bool,
    iterations: Int = 1_000,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<iterations {
        if condition() { return }
        await Task.yield()
    }
    Issue.record(
        comment ?? "waitUntil timed out after \(iterations) yields",
        sourceLocation: sourceLocation
    )
}
