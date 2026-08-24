import SwiftUI
import Scaffolding

/// The playground root: readouts on top, then one section per family of
/// navigation calls. Each section is its own small view.
struct PlaygroundView: View {
    var body: some View {
        List {
            PlaygroundStateSection()
            PlaygroundPushSection()
            PlaygroundPopSection()
            PlaygroundModalSection()
            PlaygroundAsyncSection()
        }
        .navigationTitle("Playground")
    }
}
