import SwiftUI

struct AtlasSidebar: View {
    @Environment(SplitShellCoordinator.self) private var coordinator
    var body: some View {
        List(selection: Binding<AtlasSection?>(
            get: { coordinator.section },
            set: { if let section = $0 { coordinator.selectSection(section) } }
        )) {
            ForEach(AtlasSection.allCases) { section in
                Button { coordinator.selectSection(section) } label: {
                    Label(section.rawValue, systemImage: symbol(section))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .tag(section)
                .accessibilityIdentifier("sidebar.\(section.rawValue.lowercased())")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Atlas")
        .navigationSplitViewColumnWidth(min: 180, ideal: 220, max: 280)
    }

    private func symbol(_ section: AtlasSection) -> String {
        switch section { case .discover: "globe.europe.africa"; case .saved: "bookmark"; case .lab: "square.stack.3d.up" }
    }
}
