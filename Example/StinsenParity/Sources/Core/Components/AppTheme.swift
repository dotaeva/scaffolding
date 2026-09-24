import SwiftUI

/// The handful of design decisions the whole app shares, in one place.
enum AppTheme {
    /// The accent the *user* picked in System Settings. A demo has no
    /// business inventing a brand colour, and following the system accent
    /// is what every Apple app does.
    static let tint = Color.accentColor
    static let radius: CGFloat = 10
    /// How wide body content is allowed to get. A split-view detail column
    /// on an iPad in landscape — or a Mac window pulled to full screen — is
    /// well over 1,000 pt, long enough that a line of text stops being
    /// readable and a form starts looking abandoned.
    static let readableWidth: CGFloat = 720
}

/// The semantic colours whose names differ between UIKit and AppKit.
/// Everything else uses SwiftUI's own styles (`.primary`, `.secondary`,
/// `.tint`), which need no shim.
extension ShapeStyle where Self == Color {
    /// The page behind grouped content.
    static var pageBackground: Color { Color(.systemGroupedBackground) }

    /// A raised surface for fields — one step lighter than the page in
    /// light *and* dark, which `systemBackground` is not.
    static var raisedBackground: Color { Color(.secondarySystemGroupedBackground) }
}

extension View {
    /// Caps content at a readable width and centres it in its column.
    /// A no-op on iPhone, where the screen is narrower than the cap.
    func readableColumn(_ width: CGFloat = AppTheme.readableWidth) -> some View {
        frame(maxWidth: width)
            .frame(maxWidth: .infinity)
    }
}
