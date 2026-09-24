import SwiftUI

/// Renders an enum case as its bare case name, for the readout rows.
func caseLabel(_ value: Any) -> String {
    String(describing: value)
}

/// `topDestination` and friends are optional; an em dash reads better than
/// "nil" in a readout, and the overload keeps the call sites uncluttered.
func caseLabel(_ value: (some Any)?) -> String {
    value.map { String(describing: $0) } ?? "—"
}

/// A key/value readout row — the shape Settings ▸ General ▸ About uses for
/// exactly this job, and the reason there is no bespoke tile grid here.
struct ReadoutRow: View {
    let title: String
    let value: String

    init(_ title: String, _ value: String) {
        self.title = title
        self.value = value
    }

    var body: some View {
        LabeledContent(title) {
            Text(value)
                .font(.callout.monospaced())
                .foregroundStyle(.secondary)
        }
    }
}
