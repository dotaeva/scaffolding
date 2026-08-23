import SwiftUI
import Scaffolding

/// The live coordinator tree. Reached three ways — device shake (iOS),
/// the Debug menu (macOS), and a Settings push — and its chrome adapts to
/// how it was presented.
struct HierarchyDumpSheet: View {
    // The app root is always in the environment: every ancestor
    // coordinator is injected, from any depth.
    @Environment(AppCoordinator.self) private var appCoordinator

    @State private var dump = ""
    @State private var nodeCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Coordinator tree")
                    .font(.headline)
                Spacer()
                Button("Refresh") { refresh() }
                AdaptiveDismissButton()   // only when shown as a sheet
            }
            Text("\(nodeCount) destinations in the tree")
                .font(.caption)
                .foregroundStyle(.secondary)
            ScrollView([.vertical, .horizontal]) {
                // debugHierarchy() is side-effect free — uncreated children
                // are reported, never materialised.
                Text(dump)
                    .font(.caption.monospaced())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(20)
        .presentationBackground(.thinMaterial)
        .onAppear { refresh() }
    }

    private func refresh() {
        dump = appCoordinator.debugHierarchy()
        // The structured form of the same tree, for programmatic use.
        nodeCount = count(appCoordinator.hierarchySnapshot())
    }

    private func count(_ nodes: [HierarchyNode]) -> Int {
        nodes.reduce(0) { $0 + 1 + count($1.children) }
    }
}
