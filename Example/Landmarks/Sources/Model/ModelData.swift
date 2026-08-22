/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A class the app uses to store and manage model data.
*/

import Foundation
import SwiftUI
import MapKit
import CoreLocation

/// A class the app uses to store and manage model data.
@Observable @MainActor
class ModelData {
    var landmarks: [Landmark] = []
    var landmarksByContinent: [Continent: [Landmark]] = [:]
    var featuredLandmark: Landmark?
    var selectedLandmark: Landmark? = nil
    var isLandmarkInspectorPresented: Bool = false
    
    var favoritesCollection: LandmarkCollection!
    var userCollections: [LandmarkCollection] = []

    var landmarksById: [Int: Landmark] = [:]
    var mapItemsByLandmarkId: [Int: MKMapItem] = [:]
    var mapItemsForLandmarks: [MKMapItem] {
        guard let mapItems = mapItemsByLandmarkId.values.map(\.self) as? [MKMapItem] else {
            return []
        }
        return mapItems
    }
    
    var locationFinder: LocationFinder?
    
    var searchString: String = ""
    // The sample kept a `NavigationPath` here (with a didSet dismissing the
    // inspector on pop). Navigation state now lives on the coordinators;
    // the inspector dismissal moved to the routes' `onDismiss` callbacks.

    var earnedBadges: [Badge] {
        let badges = landmarks.compactMap { landmark in
            if landmark.badge != nil,
                let progress = landmark.badgeProgress,
                progress.earned == true {
                return landmark.badge
            }
            return nil
        }
        return badges
    }

    var windowSize: CGSize = .zero

    init() {
        loadLandmarks()
        loadCollections()
        
        Task {
            do {
                let fetched = try await fetchMapItems(for: landmarks)
                
                await MainActor.run {
                    self.mapItemsByLandmarkId = fetched
                }
            } catch {
                print("Couldn't fetch map items: \(error.localizedDescription)")
            }
        }
    }
    
    func loadLandmarks() {
        landmarks = Landmark.exampleData
        landmarksByContinent = landmarksByContinent(from: landmarks)
        
        for landmark in landmarks {
            landmarksById[landmark.id] = landmark
        }

        if let fujiLandmark = landmarksById[1016] {
            featuredLandmark = fujiLandmark
        }
    }
    
    func isFavorite(_ landmark: Landmark) -> Bool {
        var isFavorite: Bool = false
        
        if favoritesCollection.landmarks.firstIndex(of: landmark) != nil {
            isFavorite = true
        }
        
        return isFavorite
    }

    func toggleFavorite(_ landmark: Landmark) {
        if isFavorite(landmark) {
            removeFavorite(landmark)
        } else {
            addFavorite(landmark)
        }
    }

    func addFavorite(_ landmark: Landmark) {
        favoritesCollection.landmarks.append(landmark)
    }

    func removeFavorite(_ landmark: Landmark) {
        if let landmarkIndex = favoritesCollection.landmarks.firstIndex(of: landmark) {
            favoritesCollection.landmarks.remove(at: landmarkIndex)
        }
    }

    func loadCollections() {
        let collectionList: [LandmarkCollection] = LandmarkCollection.exampleData

        for collection in collectionList {
            let landmarks = landmarks(for: collection.landmarkIds)
            collection.landmarks = landmarks
        }
        
        guard let favorites = collectionList.first(where: { $0.id == 1001 }) else {
            fatalError("Favorites collection missing from example data.")
        }
        favoritesCollection = favorites

        userCollections = collectionList.filter { collection in
            return collection.id != 1001
        }
    }
    
    func addUserCollection() -> LandmarkCollection {
        var nextUserCollectionId: Int = 1002
        if let lastUserCollectionId = userCollections.sorted(by: { lhs, rhs in lhs.id > rhs.id }).first?.id {
            nextUserCollectionId = lastUserCollectionId + 1
        }
        
        let newCollection = LandmarkCollection(id: nextUserCollectionId,
                                               name: String(localized: "New Collection"),
                                               description: String(localized: "Add a description for your collection here…"),
                                               landmarkIds: [],
                                               landmarks: [])
        userCollections.append(newCollection)
        return newCollection
    }

    func remove(_ collection: LandmarkCollection) {
        if let indexInUserCollections = userCollections.firstIndex(of: collection) {
            userCollections.remove(at: indexInUserCollections)
        }
    }
    
    func collection(_ collection: LandmarkCollection, contains landmark: Landmark) -> Bool {
        var collectionContainsLandmark: Bool = false
        
        if collection.landmarks.firstIndex(of: landmark) != nil {
            collectionContainsLandmark = true
        }
        
        return collectionContainsLandmark
    }

    func collectionsContaining(_ landmark: Landmark) -> [LandmarkCollection] {
        return userCollections.filter { collection in
            self.collection(collection, contains: landmark)
        }
    }

    func add(_ landmark: Landmark, to collection: LandmarkCollection) {
        if collection.landmarks.firstIndex(of: landmark) != nil {
            return
        }

        collection.landmarks.append(landmark)
    }
    
    func remove(_ landmark: Landmark, from collection: LandmarkCollection) {
        guard let index = collection.landmarks.firstIndex(of: landmark) else {
            return
        }

        collection.landmarks.remove(at: index)
    }

    func landmarks(in continent: Continent) -> [Landmark] {
        let landmarks = landmarksByContinent[continent] ?? []
        return landmarks.sorted { String(localized: $0.name) < String(localized: $1.name) }
    }
    
    private func landmarksByContinent(from landmarks: [Landmark]) -> [Continent: [Landmark]] {
        var landmarksByContinent: [Continent: [Landmark]] = [:]
        
        for landmark in landmarks {
            guard let continent = Continent(rawValue: landmark.continent) else { continue }

            if landmarksByContinent[continent] == nil {
                landmarksByContinent[continent] = [landmark]
            } else {
                landmarksByContinent[continent]?.append(landmark)
            }
        }

        return landmarksByContinent
    }
    
    private func landmarks(for landmarkIds: [Int]) -> [Landmark] {
        var landmarks: [Landmark] = []
        for landmarkId in landmarkIds {
            if let landmark = landmarksById[landmarkId] {
                landmarks.append(landmark)
            }
        }
        return landmarks
    }
    
    nonisolated private func fetchMapItems(for landmarks: [Landmark]) async throws -> [Int: MKMapItem] {
        var fetchedMapItemsByLandmarkId: [Int: MKMapItem] = [:]
        
        for landmark in landmarks {
            guard let placeID = landmark.placeID else { continue }
            
            guard let identifier = MKMapItem.Identifier(rawValue: placeID) else { continue }
            let request = MKMapItemRequest(mapItemIdentifier: identifier)
            if let mapItem = try? await request.mapItem {
                fetchedMapItemsByLandmarkId[landmark.id] = mapItem
            }
        }
        
        return fetchedMapItemsByLandmarkId
    }
}

extension ModelData {
    enum Continent: String, CaseIterable {
        case africa = "Africa"
        case antarctica = "Antarctica"
        case asia = "Asia"
        case australiaOceania = "Australia/Oceania"
        case europe = "Europe"
        case northAmerica = "North America"
        case southAmerica = "South America"
        
        var name: String {
            switch self {
            case .africa: String(localized: "Africa", comment: "The name of a continent.")
            case .antarctica: String(localized: "Antarctica", comment: "The name of a continent.")
            case .asia: String(localized: "Asia", comment: "The name of a continent.")
            case .australiaOceania: String(localized: "Australia/Oceania", comment: "The name of a continent.")
            case .europe: String(localized: "Europe", comment: "The name of a continent.")
            case .northAmerica: String(localized: "North America", comment: "The name of a continent.")
            case .southAmerica: String(localized: "South America", comment: "The name of a continent.")
            }
        }
    }
    
    static let orderedContinents: [Continent] = [.asia, .africa, .antarctica, .australiaOceania, .europe, .northAmerica, .southAmerica]
}
