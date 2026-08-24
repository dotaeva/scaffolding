import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension PlaygroundPickerCoordinator {
    /// The flow opted out of environment injection, so the screen is
    /// handed its coordinator explicitly.
    func makePicker() -> some View { PlaygroundPickerView(coordinator: self) }
}
