import Foundation

/// A route or subtree that capture or restoration skipped, and why.
public struct NavigationStateIssue: Equatable, Sendable {
    /// Why a route or subtree was skipped.
    public enum Reason: String, Sendable {
        /// A route could not be encoded.
        case encodingFailed
        /// A saved route no longer decodes.
        case decodingFailed
        /// The route is unavailable on this OS.
        case unavailableRoute
        /// The coordinator's `Destinations` is not `Codable`.
        case unsupportedCoordinator
        /// Some saved tabs failed, so the current tabs were kept.
        case invalidTabSet
    }
    /// The type name of the coordinator where the issue occurred.
    public let coordinator: String
    /// The location in the tree, such as `["tabs[1]", "entries[0]"]`.
    public let path: [String]
    /// Why the route or subtree was skipped.
    public let reason: Reason
    /// A readable description of the failure.
    public let message: String
}

/// Route counts and issues from one capture or restore.
public struct NavigationStateReport: Equatable, Sendable {
    /// Routes encoded by a capture.
    public internal(set) var capturedRoutes = 0
    /// Routes applied by a restore.
    public internal(set) var restoredRoutes = 0
    /// Routes left out because of an issue.
    public internal(set) var skippedRoutes = 0
    /// Every recorded issue, in the order found.
    public internal(set) var issues: [NavigationStateIssue] = []
    /// Whether any issue was recorded.
    public var hasIssues: Bool { !issues.isEmpty }
}

/// A snapshot and its report, from
/// ``Coordinatable/captureNavigationStateWithReport(version:)``.
public struct NavigationStateCapture: Sendable {
    /// The snapshot to persist and restore later.
    public let data: Data
    /// What the capture encoded and skipped.
    public let report: NavigationStateReport
}

@MainActor
final class NavigationStateOperation {
    var report = NavigationStateReport()
    var encodingError: (any Error)?
}

enum NavigationStateContext {
    @TaskLocal static var operation: NavigationStateOperation?
    @TaskLocal static var path: [String] = []
    @TaskLocal static var mode: NavigationRestorationMode = .replay
}

@MainActor
func withStatePath<Value>(_ location: String, _ body: () throws -> Value) rethrows -> Value {
    try NavigationStateContext.$path.withValue(NavigationStateContext.path + [location], operation: body)
}

@MainActor
func recordStateIssue(_ coordinator: any Coordinatable, at location: String? = nil, reason: NavigationStateIssue.Reason, message: String, skipped: Int = 0) {
    guard let operation = NavigationStateContext.operation else { return }
    operation.report.skippedRoutes += skipped
    operation.report.issues.append(.init(
        coordinator: String(reflecting: type(of: coordinator)),
        path: NavigationStateContext.path + (location.map { [$0] } ?? []),
        reason: reason, message: message
    ))
}

@MainActor
func encodeStateRoute<C: Coordinatable>(_ destination: Destination, owner: C, at location: String) -> Data? where C.Destinations: Encodable {
    guard let route = destination.source as? C.Destinations else {
        recordStateIssue(owner, at: location, reason: .encodingFailed, message: "The destination has no source route.", skipped: 1)
        return nil
    }
    do {
        let data = try JSONEncoder().encode(route)
        NavigationStateContext.operation?.report.capturedRoutes += 1
        return data
    } catch {
        if NavigationStateContext.operation?.encodingError == nil { NavigationStateContext.operation?.encodingError = error }
        recordStateIssue(owner, at: location, reason: .encodingFailed, message: String(describing: error), skipped: 1)
        return nil
    }
}

@MainActor
func decodeStateRoute<C: Coordinatable>(_ data: Data, owner: C, at location: String) -> C.Destinations? where C.Destinations: Decodable {
    do {
        let route = try JSONDecoder().decode(C.Destinations.self, from: data)
        guard route.isAvailable else {
            recordStateIssue(owner, at: location, reason: .unavailableRoute, message: "The route is unavailable on this OS.", skipped: 1)
            return nil
        }
        return route
    } catch {
        recordStateIssue(owner, at: location, reason: .decodingFailed, message: String(describing: error), skipped: 1)
        return nil
    }
}

@MainActor
func captureStateChild(_ destination: Destination, at location: String) -> NavigationStateNode? {
    withStatePath(location) { destination.materializedCoordinatable?._captureNavigationStateNode() }
}

@MainActor
func restoreStateChild(_ node: NavigationStateNode?, into destination: Destination?, at location: String) {
    guard let node, let child = destination?.coordinatable else { return }
    withStatePath(location) { child._restoreNavigationStateNode(node) }
}

@MainActor
func didRestoreStateRoute() {
    NavigationStateContext.operation?.report.restoredRoutes += 1
}
