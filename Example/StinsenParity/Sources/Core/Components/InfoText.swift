import SwiftUI

/// The Stinsen demo's `InfoText`, kept because the explanatory blurb on
/// each screen is half of what makes a demo readable.
///
/// Drawn as a plain labelled row rather than a tinted card: inside a
/// grouped `Form` the section already *is* the card, and a second one
/// nested in it is the thing that reads as amateur on a Mac. The colour
/// lives in the glyph instead.
struct InfoText: View {
    let text: String
    var symbol: String
    var tint: Color

    init(_ text: String, symbol: String = "info.circle.fill", tint: Color = .secondary) {
        self.text = text
        self.symbol = symbol
        self.tint = tint
    }

    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 18)
                .padding(.top, 2)

            Text(text)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 3)
    }
}
