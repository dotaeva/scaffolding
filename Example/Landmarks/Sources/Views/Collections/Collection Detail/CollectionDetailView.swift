/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A view that shows a landmark collection's details, with an option to edit.
*/

import SwiftUI

/// A view that shows a landmark collection's details, with an option to edit.
struct CollectionDetailView: View {
    @Environment(ModelData.self) var modelData
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme

    @Bindable var collection: LandmarkCollection
    @State var isEditing: Bool = false
    @State var isShowingLandmarksSelection: Bool = false
    @State var isShowingDeleteConfirmation: Bool = false
    
    var body: some View {
        @Bindable var modelData = modelData
        
        ScrollView(.vertical) {
            HStack {
                if isEditing {
                    CollectionDetailEditingView(collection: collection,
                                                isShowingLandmarksSelection: $isShowingLandmarksSelection,
                                                isShowingDeleteConfirmation: $isShowingDeleteConfirmation)
                } else {
                    CollectionDetailDisplayView(collection: collection)
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        #if os(iOS)
        .background(Color(uiColor: isEditing && colorScheme == .light ? .systemGray5 : .systemBackground))
        #endif
        #if os(macOS)
        .background(Color(nsColor: isEditing && colorScheme == .light ? .secondarySystemFill : .windowBackgroundColor))
        #endif
        .navigationBarBackButtonHidden(isEditing)
        .toolbar(removing: .title)
        .sheet(isPresented: $isShowingLandmarksSelection) {
            LandmarksSelectionList(landmarks: $collection.landmarks)
                .frame(minWidth: 200.0, minHeight: 400.0)
        }
        .toolbar {
            #if os(macOS)
            let deleteButtonPlacement: ToolbarItemPlacement = .secondaryAction
            let editButtonPlacement: ToolbarItemPlacement = .automatic
            #elseif os(iOS)
            let deleteButtonPlacement: ToolbarItemPlacement = .topBarLeading
            let editButtonPlacement: ToolbarItemPlacement = .topBarTrailing
            #endif
            if isEditing && !collection.isFavoritesCollection {
                ToolbarItem(placement: deleteButtonPlacement) {
                    deleteCollectionToolbarItemButton
                }
            }
            ToolbarItem(placement: editButtonPlacement) {
                Button() {
                    withAnimation {
                        isEditing.toggle()
                    }
                } label: {
                    if isEditing {
                        Image(systemName: "checkmark")
                            .transition(.editButtonTransition())
                    } else {
                        Text("Edit", comment: "The text label on a button to switch to editor mode.")
                    }
                }
            }
        }
    }
        
    var deleteCollectionToolbarItemButton: some View {
        Button(role: .destructive) {
            isShowingDeleteConfirmation = true
        } label: {
            Image(systemName: "trash")
                .foregroundStyle(.red)
        }
        .confirmationDialog("Delete?",
                            isPresented: $isShowingDeleteConfirmation,
                            presenting: collection) { collection in
            Button(role: .destructive) {
                // Remove collection from model data
                modelData.remove(collection)
                
                isEditing = false
                dismiss()
            } label: {
                Text("Delete", comment: "Delete button shown in an alert asking for confirmation to delete the collection.")
            }
            Button("Keep") {
                isShowingDeleteConfirmation = false
            }
        } message: { details in
            Text("Select Delete to permanently remove ‘\(collection.name)’.",
                 comment: "Message in an alert asking the person whether they want to delete a collection with a given name.")
        }
    }
}

extension AnyTransition {
    @MainActor static func editButtonTransition() -> AnyTransition {
        .asymmetric(insertion: .init(.symbolEffect(.drawOn)), removal: .opacity)
    }
}

#Preview {
    let modelData = ModelData()
    let previewCollection = modelData.userCollections.last!

    NavigationStack {
        CollectionDetailView(collection: previewCollection)
            .environment(modelData)
    }
}

