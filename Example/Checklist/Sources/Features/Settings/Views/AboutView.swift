import SwiftUI

/// A map of the demo, so anyone opening the project knows where to look.
struct AboutView: View {
    var body: some View {
        List {
            Section {
                Text("Checklist is a Scaffolding sample: coordinators own every "
                     + "transition, ViewModels own the data, and views own only layout.")
            }
            Section("Shells") {
                row("square.grid.2x2", "MainTabCoordinator", "iPhone — tab tuples, TabRole, badge, dynamic tab, shouldSelect")
                row("sidebar.left", "MainSplitCoordinator", "iPad & Mac — three columns, focus mode, split-hosted sheets")
                row("arrow.triangle.2.circlepath", "AppCoordinator", "root swap, deep links, whole-tree state restoration")
            }
            Section("Flows") {
                row("calendar", "TodayCoordinator", "pushes, policies, cover, awaited sub-flow")
                row("list.bullet", "ListsCoordinator", "three levels on one stack")
                row("checklist", "TodoDetailCoordinator", "pushed on iPhone, a column on iPad — same code")
                row("plus.circle", "NewTodoCoordinator", "returns a value; routeAndWait inside a modal")
                row("tag", "TagPickerCoordinator", "injectsCoordinator: false, init-injected instead")
            }
            Section {
                Label("Shake (⌃⌘Z in the simulator) or ⇧⌘D on Mac dumps the live tree.",
                      systemImage: "hand.tap")
                    .font(.footnote)
            }
        }
        .navigationTitle("About")
    }

    private func row(_ symbol: String, _ title: String, _ detail: String) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: symbol)
        }
    }
}
