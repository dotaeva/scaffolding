import SwiftUI

/// View-only fullScreenCover awaited with presentAndWait.
struct PinChangeScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pin = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("New PIN")
                .font(.title2.weight(.semibold))
            SecureField("••••", text: $pin)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title)
                .padding(14)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 12))
                .frame(width: 160)
            Button("Save") {
                // Native dismissal — it resumes the presenter's
                // presentAndWait just the same.
                dismiss()
            }
            .buttonStyle(.pill)
            .disabled(pin.count < 4)
            .padding(.horizontal, 60)
            Button("Cancel") { dismiss() }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(ScreenBackground())
    }
}
