import SwiftUI
import Scaffolding

/// Names the shell that is actually running, as two plain readout rows.
///
/// Both shells are read optionally because only one of them was built: the
/// environment is keyed by concrete type, so a view that runs under either
/// has to ask for each. That is also the demo — the same screen, hosted
/// two ways, saying so.
struct ShellRows: View {
    @Environment(AuthenticatedCoordinator.self) private var tabs: AuthenticatedCoordinator?
    @Environment(AuthenticatedSplitCoordinator.self) private var split: AuthenticatedSplitCoordinator?

    var body: some View {
        ReadoutRow("shell", split != nil ? "AuthenticatedSplitCoordinator"
                                         : "AuthenticatedCoordinator")
        ReadoutRow("showing", location)
    }

    private var location: String {
        let shell: (any AuthenticatedShell)? = tabs ?? split
        return shell?.location ?? "—"
    }
}
