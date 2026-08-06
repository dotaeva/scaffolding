import SwiftUI

/// Full-width monospaced control, for rows that name the API they call.
struct ControlButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.monospaced())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
