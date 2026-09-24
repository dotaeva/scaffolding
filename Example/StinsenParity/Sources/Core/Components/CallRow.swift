import SwiftUI

/// One navigation call, as a row.
///
/// The testbed is a long column of these; a glyph per row keeps the
/// families of calls — push, pop, present, await — distinguishable without
/// giving each one its own colour.
///
/// No `.buttonStyle(.plain)`: in a `Form` row that replaces the list's own
/// row activation with the label's gesture, which the enclosing scroll
/// view delays — the first tap goes nowhere and you have to hit it twice.
/// The default style makes the entire row the hit area, and explicit
/// foreground styles keep the label from turning accent-coloured.
struct CallRow: View {
    let title: String
    let symbol: String
    var tint: Color = .secondary
    let action: () -> Void

    init(
        _ title: String,
        symbol: String,
        tint: Color = .secondary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.symbol = symbol
        self.tint = tint
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(tint)
                    .frame(width: 18)

                Text(title)
                    .font(.callout.monospaced())
                    // Color.primary, not `.primary`: inside a Button label
                    // the hierarchical style resolves against the button's
                    // own content colour, which is the accent — the rows
                    // would all come out blue.
                    .foregroundStyle(Color.primary)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
        }
    }
}
