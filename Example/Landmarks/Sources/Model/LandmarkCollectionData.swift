/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
The app's sample collection data.
*/

import Foundation

extension LandmarkCollection {
    /// The app's sample collection data.
    @MainActor static let exampleData = [
        LandmarkCollection(
            id: 1001,
            name: String(localized: .LandmarkCollectionData.favoritesName),
            description: "",
            landmarkIds: [1001, 1021, 1007, 1012],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1002,
            name: String(localized: .LandmarkCollectionData.toweringPeaksName),
            description: String(localized: .LandmarkCollectionData.toweringPeaksDescription),
            landmarkIds: [1016, 1018, 1007, 1022],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1003,
            name: String(localized: .LandmarkCollectionData._2023TripName),
            description: String(localized: .LandmarkCollectionData._2023TripDescription),
            landmarkIds: [],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1004,
            name: String(localized: .LandmarkCollectionData.sweetDesertsName),
            description: String(localized: .LandmarkCollectionData.sweetDesertsDescription),
            landmarkIds: [1006, 1001, 1008],
            landmarks: []
        ),
        
        LandmarkCollection(
            id: 1005,
            name: String(localized: .LandmarkCollectionData.icyWonderlandName),
            description: String(localized: .LandmarkCollectionData.icyWonderlandDescription),
            landmarkIds: [],
            landmarks: []
        )
    ]
}
