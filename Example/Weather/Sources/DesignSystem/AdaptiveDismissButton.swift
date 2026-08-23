import SwiftUI
import Scaffolding

/// A close control that only renders when this *view* was presented
/// modally — the canonical use of the `\.destination` environment value.
///
/// Right for view-only modals (the hierarchy dump, the radar cover),
/// where the view is the destination. The root screen of a *presented
/// coordinator* reads `.root` here instead — its modal state lives on
/// the flow, so such screens key off `coordinator.routeType` (see
/// SettingsScreen).
struct AdaptiveDismissButton: View {
    @Environment(\.destination) private var destination
    // Scaffolding wraps NavigationStack, so SwiftUI's native dismiss
    // closes both pushes and modals.
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        if destination.routeType.isModal {
            Button("Close") { dismiss() }
        }
    }
}
