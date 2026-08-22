/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A menu a person uses to add or remove a landmark from a collection.
*/

import SwiftUI

/// A menu a person uses to add or remove a landmark from a collection.
struct LandmarkCollectionsMenu: View {
    @Environment(ModelData.self) private var modelData
    let landmark: Landmark

    var body: some View {
        Menu("Collections", systemImage: "book.closed") {
            ForEach(modelData.userCollections) {
                @Bindable var collection = $0
                Toggle(collection.name, isOn: $collection[contains: landmark])
            }
        }
        .menuIndicator(.hidden)
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1016] ?? modelData.landmarks.first!

    LandmarkCollectionsMenu(landmark: previewLandmark)
        .environment(modelData)
}
