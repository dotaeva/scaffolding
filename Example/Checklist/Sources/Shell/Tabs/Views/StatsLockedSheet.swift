import SwiftUI
import Scaffolding

/// Shown when `shouldSelect` vetoes the Stats tab. A view-only modal has
/// no navigation container of its own, so it lays out its own header and
/// close control rather than using a toolbar.
struct StatsLockedSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 44))
                .foregroundStyle(.tint)
                .symbolEffect(.pulse)
            Text("Nothing to chart yet")
                .font(.title3.bold())
            Text("Complete at least one task and the Stats tab will open. "
                 + "The tab coordinator vetoed the switch and showed this instead.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("OK") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(28)
        .frame(maxWidth: 420)
        .sheetSizing(minHeight: 260, idealHeight: 300)
    }
}
