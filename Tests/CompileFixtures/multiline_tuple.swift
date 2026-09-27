import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable final class Probe: TabCoordinatable { var tabItems = TabItems<Probe>(tabs: [.home]); func home() -> (some View,
 some View) { (EmptyView(), Text("Home")) } }
