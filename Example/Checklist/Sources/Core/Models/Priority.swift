import SwiftUI

/// Task priority. `Codable` so it can ride along in a route payload, and
/// `CaseIterable` so a native `Picker` can enumerate it.
enum Priority: Int, Codable, CaseIterable, Identifiable, Comparable, Sendable {
    case none, low, medium, high

    var id: Int { rawValue }

    var name: String {
        switch self {
        case .none: "None"
        case .low: "Low"
        case .medium: "Medium"
        case .high: "High"
        }
    }

    /// `!`, `!!`, `!!!` — the way Reminders renders priority inline.
    var marker: String? {
        switch self {
        case .none: nil
        case .low: "!"
        case .medium: "!!"
        case .high: "!!!"
        }
    }

    var tint: Color {
        switch self {
        case .none: .secondary
        case .low: .blue
        case .medium: .orange
        case .high: .red
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
