import SwiftUI

/// Shared dark backdrop for all demo screens.
struct ScreenBackground: View {
    static let color = Color(red: 0.035, green: 0.035, blue: 0.045)

    var body: some View {
        Self.color
            .ignoresSafeArea()
    }
}
