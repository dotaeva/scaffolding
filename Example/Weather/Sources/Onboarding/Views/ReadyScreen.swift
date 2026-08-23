import SwiftUI
import Scaffolding

struct ReadyScreen: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
            Text("All set")
                .font(.title.bold())
            Text("Temperatures in \(store.units == .celsius ? "Celsius" : "Fahrenheit"). You can change this later in Settings.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
            Spacer()
            Button("Start") {
                // Delivers the result through the presenter-installed
                // closure; AppCoordinator swaps the root atomically.
                coordinator.finish()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            Button("Start over") {
                // popToRoot() — back to the welcome screen in one step.
                coordinator.startOver()
            }
            .font(.footnote)
        }
        .padding(24)
        .skyBackground(.partlyCloudy)
        .navigationTitle("Ready")
    }
}
