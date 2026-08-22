/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a grid of landmark collections.
*/

import SwiftUI

/// A view that shows a grid of landmark collections.
struct CollectionsGrid: View {
    @Environment(ModelData.self) var modelData
    // Optional read: SwiftUI can re-evaluate this view's environment in a
    // detached context while the detail column is replaced by a deep link.
    @Environment(CollectionsCoordinator.self) private var coordinator: CollectionsCoordinator?

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Constants.collectionGridSpacing) {
                ForEach(modelData.userCollections, id: \.id) { collection in
                    Button {
                        coordinator?.showCollection(collection)
                    } label: {
                        CollectionListItemView(collection: collection)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.trailing, Constants.standardPadding)
    }
    
    private var columns: [GridItem] {
        [ GridItem(.adaptive(minimum: Constants.collectionGridItemMinSize,
                             maximum: Constants.collectionGridItemMaxSize),
                   spacing: Constants.collectionGridSpacing) ]
    }
}

#Preview {
    let modelData = ModelData()

    CollectionsGrid()
        .environment(modelData)
}
