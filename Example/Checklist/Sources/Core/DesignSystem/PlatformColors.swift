import SwiftUI

/// `String(describing:)` on an optional enum prints the whole
/// `Optional(Module.Type.case)` mouthful. Debug rows want just `.case`.
func caseLabel(_ value: Any?) -> String {
    guard let value else { return "none" }
    return ".\(value)"
}

/// The handful of semantic colors whose names differ between UIKit and
/// AppKit. Everything else in the app uses SwiftUI's own semantic styles
/// (`.primary`, `.secondary`, `.tint`, `.red`), which need no shim.
extension ShapeStyle where Self == Color {
    /// The grouped-content background, one step in from the window.
    static var groupedBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.secondarySystemBackground)
        #endif
    }

    /// A raised surface for cards and callouts.
    static var raisedBackground: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(.tertiarySystemBackground)
        #endif
    }
}
