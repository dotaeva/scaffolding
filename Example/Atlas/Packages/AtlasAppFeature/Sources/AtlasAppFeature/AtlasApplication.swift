import Foundation
import Observation
import AtlasDomain

/// One durable collection per application; every window receives its own navigation tree.
@MainActor @Observable
public final class AtlasApplication {
    public let store: AtlasStore

    public init() {
        let arguments = ProcessInfo.processInfo.arguments
        let reset = arguments.contains("--atlas-fresh-session")
        let testing = reset || arguments.contains("--atlas-testing")
        let directory = URL.applicationSupportDirectory.appending(path: "ScaffoldingAtlas", directoryHint: .isDirectory)
        let file = directory.appending(path: testing ? "UITests/collection.json" : "collection.json")
        store = AtlasStore(storageURL: file, reset: reset)
    }
}
