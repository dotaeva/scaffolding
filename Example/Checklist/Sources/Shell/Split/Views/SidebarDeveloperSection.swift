import SwiftUI
import Scaffolding

/// The sidebar's developer row: the navigation playground, which takes
/// over the detail column rather than opening as a modal.
struct SidebarDeveloperSection: View {
    @Environment(MainSplitCoordinator.self) private var coordinator

    var body: some View {
        Section("Developer") {
            Button {
                coordinator.showPlayground()
            } label: {
                Label {
                    Text("Playground").foregroundStyle(.primary)
                } icon: {
                    Image(systemName: "arrow.triangle.branch")
                }
            }
            .buttonStyle(.plain)
        }
    }
}
