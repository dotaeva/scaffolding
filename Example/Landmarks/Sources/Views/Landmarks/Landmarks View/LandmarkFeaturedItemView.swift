/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows the featured landmark with a large image.
*/

import SwiftUI

/// A view that shows the featured landmark with a large image.
///
/// Navigation-agnostic: the parent supplies `onSelect`, so the same view
/// works under any flow (the sample used a NavigationLink plus a direct
/// `modelData.path.append`).
struct LandmarkFeaturedItemView: View {
    let landmark: Landmark
    let onSelect: (Landmark) -> Void

    var body: some View {
        Button {
            onSelect(landmark)
        } label: {
            Image(decorative: landmark.backgroundImageName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .clipped()
                .backgroundExtensionEffect()
                .overlay(alignment: .bottom) {
                    VStack {
                        Text("Featured Landmark", comment: "Big headline in the main image of featured landmarks.")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .opacity(0.8)
                        Text(landmark.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Button("Learn More") {
                            onSelect(landmark)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, Constants.learnMorePadding)
                    }
                    .padding([.bottom], Constants.learnMoreBottomPadding)
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let modelData = ModelData()
    let previewLandmark = modelData.landmarksById[1012] ?? modelData.landmarks.first!

    LandmarkFeaturedItemView(landmark: previewLandmark) { _ in }
        .frame(height: 400.0)
        .environment(modelData)
}
