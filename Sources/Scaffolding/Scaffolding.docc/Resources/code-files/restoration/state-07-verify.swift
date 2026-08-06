import SwiftUI
import Scaffolding

struct DebugScreen: View {
    @Environment(PlanetsCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            // hierarchyRoot walks to the top of the tree from anywhere;
            // debugHierarchy() prints it without side effects (children that
            // do not exist yet are reported as "(not yet created)").
            Text(coordinator.hierarchyRoot.debugHierarchy())
                .font(.system(.footnote, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}

// AppRootCoordinator [root]
//   root .main → AppCoordinator [tab]
//     tab[0]* .planets → PlanetsCoordinator [flow]
//       root .planets
//       push .detail
//     tab[1] .favorites → FavoritesCoordinator [flow]
//       root .list
