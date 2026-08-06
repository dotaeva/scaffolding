import SwiftUI

struct GlassTabBarTheme: Equatable {
    var activeTint: Color = .white
    var inactiveTint: Color = Color(red: 158 / 255, green: 158 / 255, blue: 166 / 255)
    /// Sliding highlight pill color.
    var highlight: Color = .white.opacity(0.14)
    /// Dark tint layered over the liquid glass.
    var glassTint: Color = Color(red: 10 / 255, green: 10 / 255, blue: 12 / 255).opacity(0.55)
}
