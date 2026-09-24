import Foundation
import Scaffolding
import AtlasDomain

private struct AtlasCheckpoint: Codable {
    let version: Int
    let layout: AtlasLayout
    let createdAt: Date?
    let navigation: Data
}

extension AtlasCoordinator {
    public var checkpointDate: Date? {
        guard let checkpointData else { return nil }
        return (try? JSONDecoder().decode(AtlasCheckpoint.self, from: checkpointData))?.createdAt
    }

    public func saveCheckpoint() {
        guard isRoot(.workspace) else {
            session.show("Start exploring before saving a navigation checkpoint.")
            return
        }
        guard !containsModal(hierarchySnapshot()) else {
            session.show("Finish or close the current form before saving a checkpoint.")
            return
        }
        do {
            checkpointData = try JSONEncoder().encode(AtlasCheckpoint(
                version: 2, layout: layout, createdAt: Date(),
                navigation: captureNavigationState()
            ))
            session.show("Navigation checkpoint saved. Your collection is saved separately.")
        } catch {
            session.show("The navigation checkpoint could not be saved.")
        }
    }

    public func restoreCheckpoint() {
        guard let checkpointData else { return }
        do {
            let checkpoint = try JSONDecoder().decode(AtlasCheckpoint.self, from: checkpointData)
            guard (1...2).contains(checkpoint.version) else { throw CheckpointError.unsupportedVersion }
            try restoreNavigationState(from: checkpoint.navigation, mode: .replace)
            layout = checkpoint.layout
            session.show("Navigation restored. Your latest saved places and journeys are unchanged.")
        } catch {
            self.checkpointData = nil
            session.show("This checkpoint is unavailable. Save a new one in the Lab.")
        }
    }

    /// Scene storage is scoped to one window. Repeated view tasks never reset navigation.
    public func bootstrap(checkpoint: Data?) {
        guard !didBootstrap else { return }
        didBootstrap = true
        if let checkpoint {
            checkpointData = checkpoint
            restoreCheckpoint()
        }
        if isRoot(.welcome), store.hasStarted { setRoot(.workspace(layout: layout)) }
    }

    private func containsModal(_ nodes: [HierarchyNode]) -> Bool {
        nodes.contains { $0.role.isModal || containsModal($0.children) }
    }
}

private enum CheckpointError: Error { case unsupportedVersion }
