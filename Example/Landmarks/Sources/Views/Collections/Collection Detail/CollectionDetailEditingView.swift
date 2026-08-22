/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that lets a person edit a collection's title, description, and list of landmarks.
*/

import SwiftUI

/// A view that lets a person edit a collection's title, description, and list of landmarks.
struct CollectionDetailEditingView: View {
    
    @Bindable var collection: LandmarkCollection
    @Binding var isShowingLandmarksSelection: Bool
    @Binding var isShowingDeleteConfirmation: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Title")
                Spacer()
            }
            .foregroundColor(.secondary)
            .font(.title2)
            .fontWeight(.semibold)
            // Adjust the vertical padding due to the TextEditor.
            .padding(.bottom, collection.isFavoritesCollection ? 0 : -2)
            .padding([.top])
            
            VStack {
                if collection.isFavoritesCollection {
                    HStack {
                        Text(collection.name)
                            .font(.largeTitle)
                        Spacer()
                    }
                    .padding()
                } else {
                    TextField("Name", text: $collection.name)
                        .padding()
                        .textFieldStyle(.plain)
                }
            }
            .background(Constants.editingBackgroundStyle, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
            
            HStack {
                Text("Description")
                Spacer()
            }
            .foregroundColor(.secondary)
            .font(.title2)
            .fontWeight(.semibold)
            .padding(.bottom, -2) // Adjust the vertical padding due to the TextEditor.
            .padding([.top])
            
            if !collection.isFavoritesCollection {
                VStack() {
                    TextEditor(text: $collection.description)
                        .scrollContentBackground(.hidden)
                        .frame(height: Constants.textEditorHeight)
                        .padding()
                }
                .background(Constants.editingBackgroundStyle, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
            }
            
            HStack {
                Text("Landmarks")
                Spacer()
            }
            .foregroundColor(.secondary)
            .font(.title2)
            .fontWeight(.semibold)
            .padding([.top])
            
            VStack {
                HStack {
                    Spacer()
                    Button("Select") {
                        isShowingLandmarksSelection.toggle()
                    }
                    .padding([.top, .leading, .trailing])
                }
                LandmarksGrid(landmarks: $collection.landmarks, forEditing: true)
                    .padding([.leading, .trailing, .bottom])
            }
            .background(Constants.editingBackgroundStyle, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
        }
        .padding([.leading, .trailing], Constants.leadingContentInset)
        
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    CollectionDetailEditingView(collection: previewCollection,
                                isShowingLandmarksSelection: .constant(false),
                                isShowingDeleteConfirmation: .constant(false))
}

