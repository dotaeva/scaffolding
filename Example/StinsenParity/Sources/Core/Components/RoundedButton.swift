import SwiftUI

/// The demo's one piece of custom chrome, matching the Stinsen sample's
/// three button weights. Everything else is stock SwiftUI.
struct RoundedButton: View {
    enum Style {
        case primary, secondary, tertiary
    }

    let title: String
    let style: Style
    let action: () -> Void

    init(_ title: String, style: Style = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }

    private var label: some View {
        Text(title)
            .font(.body.weight(.semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)
    }

    var body: some View {
        switch style {
        case .primary:
            // The label carries the width: a bordered button sizes to its
            // content, so framing the Button itself does nothing.
            Button(action: action) { label }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 12))
        case .secondary:
            Button(action: action) { label }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .buttonBorderShape(.roundedRectangle(radius: 12))
        case .tertiary:
            Button(title, action: action)
                .buttonStyle(.borderless)
                .controlSize(.regular)
        }
    }
}
