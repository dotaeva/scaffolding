import SwiftUI
import Scaffolding

struct UnitsStepScreen: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @Environment(WeatherStore.self) private var store

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            Text("How do you read temperatures?")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            ForEach(Units.allCases) { units in
                Button {
                    // Writes domain state, then routes — both on the
                    // coordinator, never in the view.
                    coordinator.choose(units)
                } label: {
                    HStack {
                        Text(units.label)
                        Spacer()
                        if store.units == units {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: 360)
            Spacer()
        }
        .padding(24)
        .skyBackground(.partlyCloudy)
        .navigationTitle("Units")
    }
}
