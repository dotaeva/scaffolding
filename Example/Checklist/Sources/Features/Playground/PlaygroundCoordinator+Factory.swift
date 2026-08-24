import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension PlaygroundCoordinator {
    func makePlayground() -> some View { PlaygroundView() }

    /// A distinct case, so the meta-based pops have something to aim at
    /// that is not the root.
    func makeLeaf(label: String) -> some View { PlaygroundLeafView(label: label) }

    /// A child *coordinator* pushed onto this stack — it can dismiss
    /// itself and read its ancestors.
    func makeChild() -> any Coordinatable { PlaygroundChildCoordinator() }

    /// View-only modals: no coordinator inside, so the presenter closes them.
    func makeSheet() -> some View { PlaygroundModalView(title: "Sheet") }

    func makeCover() -> some View { PlaygroundModalView(title: "Full-screen cover") }

    /// A sub-flow whose whole job is returning a value.
    func makePicker() -> any Coordinatable { PlaygroundPickerCoordinator() }
}
