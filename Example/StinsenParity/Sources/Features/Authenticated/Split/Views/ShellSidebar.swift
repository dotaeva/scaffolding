import SwiftUI
import Scaffolding

/// The split view's first column: the four sections the iPhone shows as
/// tabs.
///
/// Shaped after System Settings — the account in its own group at the top,
/// then one unlabelled group of rows. Selection *highlight* is the native
/// source list's own; which columns follow from it is the coordinator's
/// business, and the row never knows whether picking it swaps one column
/// or two.
struct ShellSidebar: View {
    @Environment(AuthenticatedSplitCoordinator.self) private var coordinator

    let user: User

    var body: some View {
        List(selection: selection) {
            Section {
                account.tag(ShellSection.profile)
            }

            Section {
                ForEach(ShellSection.listed) { section in
                    row(section).tag(section)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Scaffolding")
        .navigationSplitViewColumnWidth(min: 210, ideal: 240, max: 320)
    }

    /// An `HStack` rather than a `Label`, because `Label` fixes the gap
    /// between glyph and title and a source list runs a wider one.
    private func row(_ section: ShellSection) -> some View {
        HStack(spacing: 9) {
            GlyphTile(symbol: section.symbol, tint: section.tint)
            Text(section.title)
        }
        .padding(.vertical, 3)
        .badge(section == .todos ? coordinator.store.all.count : 0)
    }

    /// The account row, and the way into the Profile pane — it carries
    /// `.profile` as its tag, so selecting it is selecting that section.
    /// A mark half again the size of a section glyph, as in Settings.
    private var account: some View {
        HStack(spacing: 10) {
            AccountAvatar(size: 34)

            VStack(alignment: .leading, spacing: 1) {
                Text(user.username)
                    .font(.subheadline)
                    .lineLimit(1)
                Text("Signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 3)
    }

    private var selection: Binding<ShellSection?> {
        Binding(
            get: { coordinator.section },
            set: { $0.map(coordinator.select) }
        )
    }
}
