import SwiftUI
import Scaffolding

/// A Done button that renders only when *this view* is the presented
/// destination — the canonical use of the `\.destination` environment
/// value that Scaffolding injects.
///
/// Note the distinction the demo leans on: a view-only modal is itself the
/// destination, so `\.destination` knows. The root screen of a *presented
/// coordinator* reads `.root` here instead, because the modal state lives
/// on the flow — those screens use `coordinator.routeType` (see
/// `SettingsView`).
struct ModalDismissButton: View {
    @Environment(\.destination) private var destination
    // Scaffolding wraps NavigationStack, so the native dismiss closes
    // pushes and modals alike.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if destination.routeType.isModal {
            Button("Done") { dismiss() }
        }
    }
}
