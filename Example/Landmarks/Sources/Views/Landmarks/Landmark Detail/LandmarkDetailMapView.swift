/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a single landmark on a map.
*/

import SwiftUI
import MapKit

/// A view that shows a single landmark on a map.
struct LandmarkDetailMapView: View {
    let landmark: Landmark
    var landmarkMapItem: MKMapItem?
    @State var mapCameraPositionForLandmark: MapCameraPosition = .automatic

    var body: some View {
        Map(position: $mapCameraPositionForLandmark, interactionModes: []) {
            if let landmarkMapItem = landmarkMapItem {
                Marker(item: landmarkMapItem)
            }
        }
        .onAppear {
            mapCameraPositionForLandmark = .region(landmark.coordinateRegion)
        }
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!
    let previewMapItem = modelData.mapItemsByLandmarkId[1012]

    LandmarkDetailMapView(landmark: previewLandmark, landmarkMapItem: previewMapItem)
}
