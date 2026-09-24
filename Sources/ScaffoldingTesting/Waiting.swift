//
//  Waiting.swift
//  ScaffoldingTesting
//

import Testing

/// Legacy yield-count waiting. Use the deadline-based overload instead.
/// This overload remains for source compatibility with explicit `iterations:`.
@available(*, deprecated, message: "Use the timeout: overload, which waits against a deadline and returns success or failure.")
@MainActor
public func waitUntil(
    _ condition: @MainActor () -> Bool,
    iterations: Int,
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) async {
    for _ in 0..<max(0, iterations) {
        if Task.isCancelled { return }
        if condition() { return }
        await Task.yield()
    }
    Issue.record(
        comment ?? "waitUntil timed out after \(iterations) yields",
        sourceLocation: sourceLocation
    )
}

/// Waits until a condition holds or a monotonic deadline is reached.
/// Returns false on cancellation without recording an issue. A timeout records
/// an issue at the call site and returns false, so callers can stop the test.
///
/// ```swift
/// guard await waitUntil({ coordinator.isPresentingModal }, timeout: .seconds(2)) else { return }
/// coordinator.dismissPresentedModal()
/// ```
@MainActor
@discardableResult
public func waitUntil(
    _ condition: @MainActor () -> Bool,
    timeout: Duration = .seconds(5),
    pollInterval: Duration = .milliseconds(1),
    _ comment: Comment? = nil,
    sourceLocation: SourceLocation = #_sourceLocation
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)
    while !Task.isCancelled {
        if condition() { return true }
        guard clock.now < deadline else { break }
        do {
            try await clock.sleep(until: min(deadline, clock.now.advanced(by: max(pollInterval, .milliseconds(1)))))
        } catch { return false }
    }
    guard !Task.isCancelled else { return false }
    Issue.record(comment ?? "waitUntil timed out after \(timeout)", sourceLocation: sourceLocation)
    return false
}
