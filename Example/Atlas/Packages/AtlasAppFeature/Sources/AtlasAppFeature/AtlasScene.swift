import SwiftUI
import Scaffolding
import AtlasDomain

/// Each WindowGroup instance owns an independent coordinator tree and checkpoint.
public struct AtlasScene: View {
    @State private var coordinator: AtlasCoordinator
    @SceneStorage("atlas.checkpoint.v1") private var checkpoint = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(application: AtlasApplication) {
        _coordinator = State(initialValue: AtlasCoordinator(store: application.store))
    }

    public var body: some View {
        coordinator.view
            .task { prepareSession() }
            .onChange(of: coordinator.checkpointData) { _, value in
                checkpoint = value?.base64EncodedString() ?? ""
            }
            .onOpenURL {
                // A launch link must land after restoration, regardless of callback order.
                prepareSession()
                coordinator.handle($0)
            }
    }

    private func prepareSession() {
        guard !coordinator.didBootstrap else { return }
        if ProcessInfo.processInfo.arguments.contains("--atlas-fresh-session") { checkpoint = "" }
        #if os(macOS)
        coordinator.layout = .split
        #else
        coordinator.layout = horizontalSizeClass == .regular ? .split : .tabs
        #endif
        coordinator.bootstrap(checkpoint: checkpoint.isEmpty ? nil : Data(base64Encoded: checkpoint))
    }
}
