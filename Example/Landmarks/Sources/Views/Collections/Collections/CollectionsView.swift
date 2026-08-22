/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a person's favorite landmarks and custom landmark collections.
*/

import SwiftUI

/// A view that shows a person's favorite landmarks and custom landmark collections.
struct CollectionsView: View {
    @Environment(ModelData.self) var modelData
    // Optional read: SwiftUI can re-evaluate this view's environment in a
    // detached context while the detail column is replaced by a deep link.
    @Environment(CollectionsCoordinator.self) private var coordinator: CollectionsCoordinator?

    var body: some View {
        @Bindable var modelData = modelData

        ScrollView(.vertical) {
            LazyVStack {
                HStack {
                    CollectionTitleView(title: "Favorites", comment: "Section title above favorite collections.")
                    Spacer()
                }
                .padding(.leading, Constants.leadingContentInset)
                
                LandmarkHorizontalListView(landmarkList: modelData.favoritesCollection.landmarks) { landmark in
                    coordinator?.showLandmark(landmark)
                }
                    .containerRelativeFrame(.vertical) { height, axis in
                        let proposedHeight = height * Constants.landmarkListPercentOfHeight
                        if proposedHeight > Constants.landmarkListMinimumHeight {
                            return proposedHeight
                        }
                        return Constants.landmarkListMinimumHeight
                    }

                HStack {
                    CollectionTitleView(title: "My Collections", comment: "Section title above the person's collections.")
                    Spacer()
                }
                .padding(.leading, Constants.leadingContentInset)
                
                CollectionsGrid()
                    .padding(.leading, Constants.leadingContentInset)
            }
        }
        .ignoresSafeArea(.keyboard, edges: [.bottom])
        .navigationTitle("Collections")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    coordinator?.createCollection()
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        // The sample declared `.navigationDestination(for:)` pairs here —
        // the coordinator's routes own those mappings now.
    }
}

private struct CollectionTitleView: View {
    let title: LocalizedStringKey
    let comment: StaticString
    
    var body: some View {
        Text(title, comment: comment)
            .font(.title2)
            .bold()
            .padding(.top, Constants.titleTopPadding)
    }
}

#Preview {
    CollectionsView()
        .environment(ModelData())
}
