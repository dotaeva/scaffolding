/*
Scaffolding port of Apple's "Landmarks: Building an app with Liquid Glass"
sample. See LICENSE.txt for the sample's licensing information.

Abstract:
The flow behind the Collections page in the detail column.
*/

import SwiftUI
import Observation
import Scaffolding

/// The Collections page: favorites and user collections at the root,
/// collection and landmark details pushed on top.
@MainActor @Observable @Scaffoldable
final class CollectionsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<CollectionsCoordinator>(root: .home)

    let modelData: ModelData

    init(modelData: ModelData) {
        self.modelData = modelData
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func home() -> some View { CollectionsView() }
    func landmarkDetail(landmark: Landmark) -> some View {
        LandmarkDetailView(landmark: landmark)
    }
    func collectionDetail(collection: LandmarkCollection) -> some View {
        CollectionDetailView(collection: collection)
    }
}

// MARK: - Navigation

extension CollectionsCoordinator {
    /// See `LandmarksPageCoordinator.showLandmark` — the `onDismiss`
    /// reproduces the sample's inspector-dismissal-on-pop behavior.
    func showLandmark(_ landmark: Landmark) {
        route(to: .landmarkDetail(landmark: landmark), policy: .distinct) { [weak self] in
            self?.modelData.isLandmarkInspectorPresented = false
        }
    }

    func showCollection(_ collection: LandmarkCollection) {
        route(to: .collectionDetail(collection: collection), policy: .distinct)
    }

    /// Replaces the sample's `modelData.path.append(newCollection)` from
    /// the toolbar plus button.
    func createCollection() {
        let collection = modelData.addUserCollection()
        route(to: .collectionDetail(collection: collection))
    }
}
