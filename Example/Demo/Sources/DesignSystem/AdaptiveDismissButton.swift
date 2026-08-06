import SwiftUI
import Scaffolding

/// Close control driven by `@Environment(\.destination)` — the metadata
/// Scaffolding injects for how the current screen was reached. Modals get a
/// Close button; pushed screens keep the system back button; roots get
/// nothing. One component, correct in every context.
struct AdaptiveDismissButton: View {
    @Environment(\.destination) private var destination
    // Native dismiss works for pops and modals alike, because flows wrap
    // NavigationStack.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if destination.routeType.isModal {
            Button("Close") { dismiss() }
        }
    }
}
