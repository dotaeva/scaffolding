import Foundation
import Scaffolding

/// What the app root and the feature flows need from the signed-in shell,
/// whichever form the device built.
///
/// Deliberately **not** a `Coordinatable` refinement: `ancestor(ofType:)`
/// is generic over `Coordinatable`, which has an associated type, so
/// `any AuthenticatedShell` could never stand in for its `T`. Keeping the
/// protocol plain lets both shells adopt it while callers still ask for
/// each concrete type in turn — which is what ``authenticatedShell()``
/// below does once, so nothing else has to.
@MainActor
protocol AuthenticatedShell: AnyObject {
    /// Where the shell currently is, for the Profile screen's readout.
    var location: String { get }

    /// Show one task, switching whatever the shell has to switch first.
    func openTodo(id: UUID)

    /// The deep-link entry point: resolve the name against the shell's own
    /// store, then reuse the same walk.
    func openTodo(named name: String)
}

extension Coordinatable {
    /// The signed-in shell above this coordinator, tabs or columns.
    ///
    /// Exactly one of these is non-nil — whichever shell the device built.
    func authenticatedShell() -> (any AuthenticatedShell)? {
        if let tabs = ancestor(ofType: AuthenticatedCoordinator.self) { return tabs }
        return ancestor(ofType: AuthenticatedSplitCoordinator.self)
    }
}
