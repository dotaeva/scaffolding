/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A button for adding or removing a landmark from the list of favorite landmarks.
*/

import SwiftUI

/// A button for adding or removing a landmark from the list of favorite landmarks.
struct LandmarkFavoriteButton: View {
    @Environment(ModelData.self) private var modelData
    let landmark: Landmark

    var body: some View {
        Button {
            modelData.toggleFavorite(landmark)
        } label: {
            FavoriteButtonLabel(isFavorite: modelData.isFavorite(landmark))
        }
    }
}

private struct FavoriteButtonLabel: View {
    var isFavorite: Bool
    var body: some View {
        Label(isFavorite ? "Unfavorite" : "Favorite", systemImage: "heart")
            .symbolVariant(isFavorite ? .fill : .none)
    }
}

#Preview {
    @Previewable @State var modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1016] ?? modelData.landmarks.first!

    LandmarkFavoriteButton(landmark: previewLandmark)
        .environment(modelData)
}
