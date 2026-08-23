import SwiftUI
import Scaffolding

struct WelcomeScreen: View {
    // The nearest coordinator, injected by Scaffolding. Views never hold
    // navigation state — they call methods on the coordinator.
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "cloud.sun.rain.fill")
                .font(.system(size: 72))
                .symbolRenderingMode(.multicolor)
            Text("Weather")
                .font(.largeTitle.bold())
            Text("A Scaffolding example that exercises every part of the library — coordinators own all navigation, views own none.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 420)
            Spacer()
            Button("Continue") {
                coordinator.showUnits()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .skyBackground(.partlyCloudy)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    // Preview the coordinator at its real root — there is no macro-made
    // init(initialRoute:).
    OnboardingCoordinator(store: WeatherStore(), onComplete: { }).view
        .environment(WeatherStore())
}
