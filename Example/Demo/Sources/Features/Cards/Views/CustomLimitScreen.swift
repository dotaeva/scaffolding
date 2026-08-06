import SwiftUI
import Scaffolding

struct CustomLimitScreen: View {
    @Environment(LimitCoordinator.self) private var coordinator
    @State private var text = ""

    var body: some View {
        VStack(spacing: 20) {
            TextField("Amount", text: $text)
                .keyboardType(.decimalPad)
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(14)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 12))
            Button("Save") {
                if let value = Decimal(string: text) {
                    coordinator.finish(value)
                }
            }
            .buttonStyle(.pill)
            .disabled(Decimal(string: text) == nil)
            Spacer()
        }
        .padding(20)
        .background(ScreenBackground())
        .navigationTitle("Custom limit")
        .navigationBarTitleDisplayMode(.inline)
        // Back button: provided by the LimitCoordinator's own stack.
    }
}
