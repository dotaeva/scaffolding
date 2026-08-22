/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a single landmark in a selection list.
*/

import SwiftUI

/// A view that shows a single landmark in a selection list.
struct LandmarksSelectionListItem: View {
    let landmark: Landmark
    @Binding var landmarks: [Landmark]
    
    var body: some View {
        HStack {
            Image(landmark.thumbnailImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: Constants.landmarkSelectionImageSize.width,
                       height: Constants.landmarkSelectionImageSize.height)
                .cornerRadius(Constants.landmarkSelectionImageCornerRadius)
                .padding(.trailing, Constants.standardPadding)
            Text(landmark.name)
                .font(.title3)
            Spacer()
            if landmarks.contains(landmark) {
                Image(systemName: "checkmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .indigo)
                    .font(.title)
                    .padding(.trailing, Constants.standardPadding)

            } else {
                Image(systemName: "circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.gray)
                    .font(.title)
                    .padding(.trailing, Constants.standardPadding)

            }
        }
    }
}

#Preview {
    @Previewable @State var landmarks: [Landmark] = []
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!
    
    LandmarksSelectionListItem(landmark: previewLandmark, landmarks: $landmarks)
}
