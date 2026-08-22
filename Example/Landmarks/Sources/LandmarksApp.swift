/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The main app declaration.
*/

import SwiftUI

/// The main app declaration.
@main
struct LandmarksApp: App {
    /// An object that manages the app's data and state.
    @State private var modelData: ModelData
    /// The root coordinator — mounting its view is the only navigation
    /// wiring the entry point needs.
    @State private var coordinator: LandmarksSplitCoordinator

    init() {
        let modelData = ModelData()
        _modelData = State(initialValue: modelData)
        _coordinator = State(initialValue: LandmarksSplitCoordinator(modelData: modelData))
    }

    var body: some Scene {
        WindowGroup {
            coordinator.view
                .environment(modelData)
                .frame(minWidth: 375.0, minHeight: 375.0)
                // Keeps the current window's size for use in scrolling header calculations.
                .onGeometryChange(for: CGSize.self) { geometry in
                    geometry.size
                } action: {
                    modelData.windowSize = $0
                }
        }
    }
}
