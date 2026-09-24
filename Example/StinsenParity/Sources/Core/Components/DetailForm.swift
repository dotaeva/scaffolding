import SwiftUI

/// The container every detail screen uses: an inset-grouped `List`.
///
/// It was a grouped `Form` while the app also built for macOS, where that
/// is the Settings shape. On iOS the two look the same but do not behave
/// the same: a `Button` with a custom label in a `Form` row has flaky
/// first-tap handling, which is what made rows feel like they needed two
/// taps. In a `List` row the button is the row, and one tap is one tap.
///
/// It deliberately adds *nothing* around the list. An earlier version
/// capped the width here, which framed the scroll view rather than its
/// content: the scroller, the background, and the hover region all ended
/// up inset from the column. A pane fills its column; only the rows inside
/// it have margins.
struct DetailForm<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        List {
            content
        }
        .listStyle(.insetGrouped)
    }
}

/// A rounded, filled glyph tile — the sidebar rows, and anywhere else an
/// icon needs to carry a colour.
struct GlyphTile: View {
    let symbol: String
    var tint: Color = AppTheme.tint
    var size: CGFloat?

    private var side: CGFloat { size ?? 28 }

    var body: some View {
        Image(systemName: symbol)
            // Small and light *inside* the tile. A Settings glyph takes
            // little more than half its tile; one that fills the square
            // reads as a solid blob, and four of them in a row are the
            // clutter — not the tiles themselves.
            .font(.system(size: side * 0.46, weight: .regular))
            .foregroundStyle(.white)
            .frame(width: side, height: side)
            .background {
                let shape = RoundedRectangle(cornerRadius: side * 0.28, style: .continuous)
                shape
                    .fill(tint)
                    // The soft top highlight Apple's icons carry. Barely
                    // there — a colour ramp reads as noise at 20 pt, but a
                    // dead-flat square reads as a placeholder.
                    .overlay {
                        shape.fill(
                            LinearGradient(
                                colors: [.white.opacity(0.24), .white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
            }
            .shadow(color: .black.opacity(0.18), radius: 0.8, y: 0.5)
    }
}

/// The account mark: an emoji on a pale disc, the way an Apple Account
/// avatar looks in System Settings.
///
/// The disc colour is a literal rather than a semantic one on purpose —
/// an account picture keeps its own colour in light and dark, because it
/// is a picture, not chrome.
struct AccountAvatar: View {
    var size: CGFloat

    var body: some View {
        Text(verbatim: "🚀")
            .font(.system(size: size * 0.55))
            .frame(width: size, height: size)
            .background(Color(red: 0.67, green: 0.81, blue: 0.94), in: .circle)
    }
}
