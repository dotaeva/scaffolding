import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign
import AtlasWelcome
import AtlasShell

/// The composition root. Feature modules depend on its capabilities, never its type.
@MainActor @Observable @Scaffoldable(codable: true)
public final class AtlasCoordinator: RootCoordinatable, AtlasSessionActions {
    public var root = Root<AtlasCoordinator>(root: .welcome)
    public let store: AtlasStore
    public let session: AtlasSessionContext
    public internal(set) var layout: AtlasLayout
    public internal(set) var checkpointData: Data?
    var didBootstrap = false

    public init(layout: AtlasLayout = .tabs, store: AtlasStore = AtlasStore()) {
        self.layout = layout
        self.store = store
        self.session = AtlasSessionContext(store: store)
        self.session.actions = self
    }

    func welcome() -> any Coordinatable { WelcomeCoordinator(session: self) }
    func workspace(layout: AtlasLayout) -> any Coordinatable {
        switch layout {
        case .tabs: TabShellCoordinator(store: store, session: self, context: session)
        case .split: SplitShellCoordinator(store: store, session: self, context: session)
        }
    }
}

extension AtlasCoordinator {
    public var hierarchyDescription: String { debugHierarchy() }
    public var hasCheckpoint: Bool { checkpointData != nil }

    public func startExploring() {
        store.markStarted()
        session.dismissMessage()
        setRoot(.workspace(layout: layout))
    }
    public func restartWelcome() { session.dismissMessage(); setRoot(.welcome) }
    public func switchLayout(_ layout: AtlasLayout) {
        self.layout = layout
        startExploring()
        session.show("Layout changed. Your collection is saved automatically.")
    }

    public func customize(_ view: AnyView) -> some View {
        view
            .environment(\.atlasSession, session)
            .onChange(of: store.persistenceError, initial: true) { _, error in
                if let error { self.session.show(error) }
            }
    }
}

