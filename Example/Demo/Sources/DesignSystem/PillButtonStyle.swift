import SwiftUI

/// Primary action button. The app-wide white tint (AppCoordinator.customize)
/// turns .borderedProminent into a white pill with a white label — this style
/// sets the fill and label colors explicitly so contrast never depends on
/// the inherited tint.
struct PillButtonStyle: ButtonStyle {
    var fill: Color = .white
    var label: Color = .black

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            // Fading fill and label together collapses the contrast between
            // them, so the disabled state gets its own pair: a dark capsule
            // with a light label instead of gray-on-gray.
            .foregroundStyle(isEnabled ? label : .white.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isEnabled ? fill : .white.opacity(0.12), in: .capsule)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension ButtonStyle where Self == PillButtonStyle {
    static var pill: PillButtonStyle { PillButtonStyle() }
    static func pill(fill: Color, label: Color = .white) -> PillButtonStyle {
        PillButtonStyle(fill: fill, label: label)
    }
}
