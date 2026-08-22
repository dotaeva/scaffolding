/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a single landmark in a grid.
*/

import SwiftUI

/// A view that shows a single landmark in a grid.
struct LandmarkGridItemView: View {
    let landmark: Landmark

    var body: some View {
        Image(landmark.thumbnailImageName)
            .resizable()
            .aspectRatio(1, contentMode: .fill)
            .overlay {
                ReadabilityRoundedRectangle()
            }
            .clipped()
            .cornerRadius(Constants.cornerRadius)
            .overlay(alignment: .bottom) {
                Text(landmark.name)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.bottom)
            }
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1001] ?? modelData.landmarks.first!
    LandmarkGridItemView(landmark: previewLandmark)
}
