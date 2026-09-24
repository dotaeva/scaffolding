import SwiftUI

/// The four sections the signed-in shell offers: tabs on iPhone, sidebar
/// rows on iPad and Mac.
///
/// Domain state, not navigation state — the split coordinator keeps the
/// selected case and derives its columns from it, because `setContent` and
/// `setDetail` *replace* a column and need a guard that `RoutePolicy` can't
/// provide.
enum ShellSection: String, CaseIterable, Identifiable, Hashable, Sendable {
    case home
    case todos
    case profile
    case testbed

    var id: Self { self }

    /// What the sidebar lists. Profile is missing on purpose: the account
    /// row at the top *is* its entry point, the way Settings' Apple
    /// Account row opens the account pane rather than repeating itself
    /// further down.
    static let listed: [ShellSection] = [.home, .todos, .testbed]

    var title: String {
        switch self {
        case .home: "Home"
        case .todos: "Todos"
        case .profile: "Profile"
        case .testbed: "Testbed"
        }
    }

    var symbol: String {
        switch self {
        case .home: "house"
        case .todos: "checklist"
        case .profile: "person"
        case .testbed: "testtube.2"
        }
    }

    /// Sidebar glyph colour. Deliberately narrow — System Settings runs
    /// most of its list in one blue and reserves other colours for things
    /// that mean something. A rainbow of section tints is the tell of a
    /// design that had no reason for any of them.
    var tint: Color {
        switch self {
        case .home, .todos: .blue
        case .profile, .testbed: .gray
        }
    }

    /// The one-liner under the title on the section's own screen.
    var caption: String {
        switch self {
        case .home: "Favourites, and a deep link to try"
        case .todos: "A list column, a detail column"
        case .profile: "Where you are, and the way out"
        case .testbed: "Every navigation call, live"
        }
    }
}
