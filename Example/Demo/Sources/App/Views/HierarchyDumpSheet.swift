import SwiftUI
import Scaffolding

/// Debug sheet presented by the AppCoordinator on device shake (⌃⌘Z in the
/// simulator) or from the developer screen: the live coordinator tree, plus
/// save/restore of a navigation snapshot.
struct HierarchyDumpSheet: View {
    @Environment(AppCoordinator.self) private var appCoordinator

    @State private var dump = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Coordinator tree")
                    .font(.headline)
                Spacer()
                Button("Refresh") { refresh() }
                AdaptiveDismissButton()
            }

            snapshotControls

            Divider()

            ScrollView([.vertical, .horizontal]) {
                // debugHierarchy() is side-effect free — uncreated children
                // are reported, never materialised.
                Text(dump)
                    .font(.caption.monospaced())
                    // topLeading: a shorter tree than the sheet is tall would
                    // otherwise be centred in the scroll content.
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .padding(20)
        .tint(.white)
        .presentationBackground(.thinMaterial)
        .onAppear { refresh() }
    }

    /// Save and Restore both close this sheet — Save so it stays out of the
    /// snapshot, Restore because it rebuilds the tree underneath.
    private var snapshotControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Button("Save") { appCoordinator.saveSnapshot() }
                    .buttonStyle(.pill)
                Button("Restore") { appCoordinator.restoreSnapshot() }
                    .buttonStyle(.pill)
                    .disabled(!appCoordinator.hasSnapshot)
            }

            HStack {
                Text(subtitle)
                Spacer()
                if appCoordinator.hasSnapshot {
                    Button("Delete") { appCoordinator.deleteSnapshot() }
                        .foregroundStyle(.red)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private var subtitle: String {
        guard let savedAt = appCoordinator.snapshotSavedAt else {
            return "No snapshot yet"
        }
        let time = savedAt.formatted(date: .omitted, time: .standard)
        if let status = appCoordinator.snapshotStatus {
            return "\(status) · snapshot from \(time)"
        }
        return "Snapshot from \(time)"
    }

    private func refresh() {
        // The app root is the hierarchy root here; from an arbitrary
        // coordinator you'd call hierarchyRoot.debugHierarchy().
        dump = appCoordinator.debugHierarchy()
    }
}
