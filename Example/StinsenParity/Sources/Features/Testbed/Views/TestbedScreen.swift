import SwiftUI
import Scaffolding

/// The testbed root: readouts on top, then one section per family of
/// navigation calls. Each section is its own small view.
///
/// The last two cover the *shell* above this flow rather than the flow
/// itself, and each renders only when its own shell is the one that was
/// built — so iPhone gets tab controls, iPad gets column controls, and
/// neither needs a `#if`.
struct TestbedScreen: View {
    var body: some View {
        DetailForm {
            TestbedStateSection()
            TestbedPushSection()
            TestbedPopSection()
            TestbedModalSection()
            TestbedAwaitSection()
            TestbedTabSection()
            TestbedSplitSection()
        }
        .navigationTitle("Testbed")
    }
}
