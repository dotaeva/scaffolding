/*
Scaffolding port of Apple's "Landmarks: Building an app with Liquid Glass"
sample. See LICENSE.txt for the sample's licensing information.

Abstract:
The sidebar column: the app's main pages as a native selection list.
*/

import SwiftUI
import Scaffolding

/// The sidebar column. In the sample, sidebar rows *pushed* the selected
/// page; here selection is view chrome synced with the split coordinator,
/// which replaces the detail column with the page's flow.
struct SidebarView: View {
    @Environment(LandmarksSplitCoordinator.self) private var coordinator

    @State private var selection: NavigationOptions?

    var body: some View {
        List(selection: $selection) {
            Section {
                ForEach(NavigationOptions.mainPages) { page in
                    Label(page.name, systemImage: page.symbolName)
                        .tag(page)
                }
            }
        }
        .navigationTitle("Landmarks")
        .frame(minWidth: 150)
        .onAppear { selection = coordinator.selectedPage }
        // Row tap → coordinator. Selection is optional-writable, so guard
        // against the clear that follows programmatic changes.
        .onChange(of: selection) { _, page in
            guard let page else { return }
            coordinator.select(page)
        }
        .onChange(of: coordinator.selectedPage) { _, page in
            selection = page
        }
    }
}
