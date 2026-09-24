import SwiftUI
import Scaffolding

/// Returns a number to whoever is awaiting it. Its coordinator opted out
/// of environment injection, so it arrives through `init`.
struct PickerScreen: View {
    let coordinator: PickerCoordinator

    var body: some View {
        VStack(spacing: 16) {
            Text("Pick a number")
                .font(.title3.bold())

            Text("The value travels back through "
                 + "dismissCoordinator(returning:) to the awaiting call, "
                 + "which toasts it.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                ForEach([1, 2, 3], id: \.self) { value in
                    Button("\(value)") { coordinator.pick(value) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }

            Button("Cancel") { coordinator.cancel() }
                .font(.footnote)
        }
        .padding(28)
        .frame(maxWidth: 420)
    }
}
