import SwiftUI
import Scaffolding

/// The live coordinator tree. Reached three ways — device shake (iOS), the
/// Debug menu (macOS), and a push from Settings — and its chrome adapts to
/// how it arrived.
struct HierarchySheet: View {
    // Every *ancestor* coordinator is in the environment, from any depth,
    // so the app root is always reachable.
    @Environment(AppCoordinator.self) private var app

    @State private var dump = ""
    @State private var destinationCount = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("\(destinationCount) destinations", systemImage: "point.3.filled.connected.trianglepath.dotted")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button("Refresh", systemImage: "arrow.clockwise") { refresh() }
                    .labelStyle(.iconOnly)
                ModalDismissButton()
            }
            ScrollView([.vertical, .horizontal]) {
                // debugHierarchy() is side-effect free — children that
                // have not been created yet are reported, never built.
                Text(dump)
                    .font(.caption.monospaced())
                    .textSelection(.enabled)
                    .padding(.trailing, 16)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(20)
        .frame(minWidth: 320, minHeight: 260)
        .onAppear { refresh() }
    }

    private func refresh() {
        dump = app.debugHierarchy()
        // hierarchySnapshot() is the structured form of the same tree.
        destinationCount = count(app.hierarchySnapshot())
    }

    private func count(_ nodes: [HierarchyNode]) -> Int {
        nodes.reduce(0) { $0 + 1 + count($1.children) }
    }
}
