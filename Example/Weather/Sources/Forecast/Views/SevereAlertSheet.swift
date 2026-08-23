import SwiftUI
import Scaffolding

/// The severe-weather warning. Presented with swipe-down disabled — the
/// user must acknowledge — from two places: the forecast flow's banner and
/// the tab shell's radar guard. It reads the presenter's sheet
/// configuration back from the environment.
struct SevereAlertSheet: View {
    // The presenting shell differs per layout; both reads are optional so
    // the sheet works wherever it is shown.
    @Environment(MainTabCoordinator.self) private var tabs: MainTabCoordinator?
    @Environment(WeatherStore.self) private var store
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    private var alert: WeatherAlert? { store.alerts.first }

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.yellow)
            Text(alert?.title ?? "All clear")
                .font(.title3.bold())
            if let alert {
                Text("\(alert.locationName) — \(alert.message)")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            // Presenter-side configuration, read back by the presented view.
            if destination.modalConfiguration?.interactiveDismissDisabled == true {
                Text("Swipe-down is disabled — acknowledging is the only way out.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Button("Acknowledge") {
                store.acknowledgeAlerts()
                tabs?.clearAlertBadge()   // tab layout only; nil elsewhere
                // Native dismiss closes whichever coordinator presented
                // this sheet — the forecast flow's banner or the tab
                // shell's radar guard — and resolves any presentAndWait.
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
        .frame(maxWidth: 480)
        .presentationBackground(.thinMaterial)
    }
}
