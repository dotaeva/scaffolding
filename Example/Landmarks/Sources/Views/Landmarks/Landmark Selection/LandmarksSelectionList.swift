/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a list of landmarks, organized by continent, for selection.
*/

import SwiftUI

/// A view that shows a list of landmarks, organized by continent, for selection.
struct LandmarksSelectionList: View {
    @Environment(ModelData.self) var modelData
    @Binding var landmarks: [Landmark]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(ModelData.orderedContinents, id: \.self) { continent in
                    Section(header: Text(continent.name)) {
                        ForEach(modelData.landmarks(in: continent)) { landmark in
                            LandmarksSelectionListItem(landmark: landmark, landmarks: $landmarks)
                                .onTapGesture {
                                    if landmarks.contains(landmark) {
                                        if let landmarkIndex = landmarks.firstIndex(of: landmark) {
                                            landmarks.remove(at: landmarkIndex)
                                        }
                                    } else {
                                        landmarks.append(landmark)
                                    }
                                }
                        }
                    }
                }
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .navigationTitle("Select landmarks")
            .toolbar {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                }
            }
        }
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    LandmarksSelectionList(landmarks: .constant(previewCollection.landmarks))
        .environment(modelData)
}
