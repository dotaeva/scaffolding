/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A structure that defines a collection of landmarks that a person defines.
*/

import SwiftUI

/// A structure that defines a collection of landmarks that a person defines.
@Observable
class LandmarkCollection: Identifiable {
    var id: Int
    var name: String
    var description: String
    var landmarkIds: [Int]
    var landmarks: [Landmark] = []
    
    var isFavoritesCollection: Bool {
        return id == 1001
    }
    
    init(id: Int, name: String, description: String, landmarkIds: [Int], landmarks: [Landmark]) {
        self.id = id
        self.name = name
        self.description = description
        self.landmarkIds = landmarkIds
        self.landmarks = landmarks
    }
}

extension LandmarkCollection: Equatable {
    static func == (lhs: LandmarkCollection, rhs: LandmarkCollection) -> Bool {
        return lhs.id == rhs.id
    }
}

extension LandmarkCollection: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension LandmarkCollection {
    var backgroundColor: some ShapeStyle {
        #if os(iOS)
        return Color(uiColor: .systemGray5)
        #endif
        #if os(macOS)
        return Color(nsColor: .secondarySystemFill)
        #endif
    }
}

extension LandmarkCollection {
    @ViewBuilder func imageForListItem() -> some View {
        switch landmarks.count {
        case 1...3:
            Image(landmarks[0].thumbnailImageName)
                .resizable()
                .aspectRatio(1.0, contentMode: .fit)
        case 4, 4...:
            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                GridRow {
                    Image(landmarks[0].thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                    Image(landmarks[1].thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                }
                GridRow {
                    Image(landmarks[2].thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                    Image(landmarks[3].thumbnailImageName)
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                }
            }
            .cornerRadius(Constants.collectionGridItemCornerRadius)
        default:
            RoundedRectangle(cornerRadius: 8.0)
                .fill(backgroundColor)
                .aspectRatio(1.0, contentMode: .fit)
                .overlay {
                    GeometryReader { geometry in
                        Image(systemName: "book.closed")
                            .resizable()
                            .scaledToFit()
                            .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                            .offset(x: geometry.size.width / 4, y: geometry.size.height / 4)
                            #if os(iOS)
                            .foregroundColor(Color(uiColor: .systemGray3))
                            #endif
                            #if os(macOS)
                            .foregroundColor(Color(nsColor: .secondaryLabelColor).opacity(0.3))
                            #endif
                    }
                }
        }
    }
}

extension LandmarkCollection {
    subscript(contains landmark: Landmark) -> Bool {
        get {
            landmarks.contains(landmark)
        }
        set {
            if newValue, !landmarks.contains(landmark) {
                landmarks.append(landmark)
            } else if !newValue {
                landmarks.removeAll { $0.id == landmark.id }
            }
        }
    }
}
