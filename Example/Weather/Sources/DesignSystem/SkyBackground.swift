import SwiftUI

/// Full-bleed sky gradient. Applied by `ForecastCoordinator.customize`, so
/// every screen the flow shows — root, pushed days, modals stay separate —
/// shares the condition's palette without any screen knowing about it.
struct SkyBackground: ViewModifier {
    let condition: Condition

    func body(content: Content) -> some View {
        content
            .scrollContentBackground(.hidden)
            .background(
                LinearGradient(
                    colors: condition.gradient,
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
    }
}

extension View {
    func skyBackground(_ condition: Condition) -> some View {
        modifier(SkyBackground(condition: condition))
    }
}

/// Translucent card used for forecast sections.
struct WeatherCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white.opacity(0.12), in: .rect(cornerRadius: 14))
    }
}

extension View {
    func weatherCard() -> some View {
        modifier(WeatherCard())
    }
}
