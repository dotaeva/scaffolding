/*
Scaffolding port of Apple's "Landmarks: Building an app with Liquid Glass"
sample. See LICENSE.txt for the sample's licensing information.

Abstract:
The flow behind the Landmarks page in the detail column.
*/

import SwiftUI
import Observation
import Scaffolding

/// The Landmarks page: the continent browser at the root, landmark
/// details pushed on top. As a column child it builds its own
/// `NavigationStack` inside the split view.
@MainActor @Observable @Scaffoldable
final class LandmarksPageCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LandmarksPageCoordinator>(root: .home)

    let modelData: ModelData

    init(modelData: ModelData) {
        self.modelData = modelData
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func home() -> some View { LandmarksView() }
    func landmarkDetail(landmark: Landmark) -> some View {
        LandmarkDetailView(landmark: landmark)
    }
}

// MARK: - Navigation

extension LandmarksPageCoordinator {
    /// Replaces the sample's `modelData.path.append(landmark)`. The
    /// `onDismiss` reproduces the sample's `path.didSet` behavior: leaving
    /// a detail closes the inspector it may have opened.
    func showLandmark(_ landmark: Landmark) {
        route(to: .landmarkDetail(landmark: landmark), policy: .distinct) { [weak self] in
            self?.modelData.isLandmarkInspectorPresented = false
        }
    }
}
