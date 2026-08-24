import SwiftUI

/// A user list ("Work", "Home"). The `id` is a slug, which doubles as the
/// deep-link token: `checklist://list/work`.
struct TodoList: Identifiable, Codable, Hashable, Sendable {
    let id: String
    var name: String
    var symbol: String
    var colorName: ColorName

    /// A small named palette instead of an encoded `Color` — keeps the
    /// model `Codable` and the UI on semantic system colors.
    enum ColorName: String, Codable, CaseIterable, Identifiable, Sendable {
        case blue, purple, pink, orange, green, teal

        var id: String { rawValue }

        var color: Color {
            switch self {
            case .blue: .blue
            case .purple: .purple
            case .pink: .pink
            case .orange: .orange
            case .green: .green
            case .teal: .teal
            }
        }
    }

    var color: Color { colorName.color }
}
