/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that scrolls a list of landmarks horizontally.
*/

import SwiftUI

/// A view that scrolls a list of landmarks horizontally.
///
/// Navigation-agnostic: the parent supplies `onSelect`, so the same view
/// works under the Landmarks flow and the Collections flow alike.
struct LandmarkHorizontalListView: View {
    let landmarkList: [Landmark]
    let onSelect: (Landmark) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: Constants.standardPadding) {
                Spacer()
                    .frame(width: Constants.standardPadding)
                ForEach(landmarkList) { landmark in
                    Button {
                        onSelect(landmark)
                    } label: {
                        LandmarkListItemView(landmark: landmark)
                            .aspectRatio(Constants.landmarkListItemAspectRatio, contentMode: .fill)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    let modelData = ModelData()

    LandmarkHorizontalListView(landmarkList: modelData.landmarks) { _ in }
        .frame(height: 180.0)
}
