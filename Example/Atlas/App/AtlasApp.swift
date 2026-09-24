import SwiftUI
import AtlasAppFeature

@main
struct AtlasApp: App {
    @State private var application = AtlasApplication()

    var body: some Scene {
        WindowGroup { AtlasScene(application: application) }
            .defaultSize(width: 1180, height: 820)
    }
}
