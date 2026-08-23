import SwiftUI
import Scaffolding

/// Receives its coordinator through init — the flow opted out of
/// environment injection with @Scaffoldable(injectsCoordinator: false).
struct UnitsPickerScreen: View {
    let coordinator: UnitsPickerCoordinator
    let current: Units

    var body: some View {
        VStack(spacing: 12) {
            Text("Temperature Units")
                .font(.headline)
            ForEach(Units.allCases) { units in
                Button {
                    coordinator.pick(units)   // dismissCoordinator(returning:)
                } label: {
                    HStack {
                        Text(units.label)
                        Spacer()
                        if units == current {
                            Image(systemName: "checkmark")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
            Button("Cancel") {
                coordinator.cancel()
            }
            .font(.footnote)
        }
        .padding(24)
        .frame(maxWidth: 420)
        .presentationBackground(.thinMaterial)
    }
}
