/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A structure that defines the properties of a landmark.
*/

import CoreLocation
import CoreTransferable
import SwiftUI // Image
import MapKit

/// A structure that defines the properties of a landmark.
struct Landmark: Hashable, Identifiable, Transferable {
    var id: Int
    var name: LocalizedStringResource
    var continent: String
    var description: LocalizedStringResource
    var latitude: Double
    var longitude: Double
    var span: Double
    var placeID: String?
    var totalArea: Measurement<UnitArea>?
    var elevation: Elevation?
    var location: LocalizedStringResource?
    var badge: Badge?
    var badgeProgress: BadgeProgress?
    
    var backgroundImageName: String {
        return "\(id)"
    }
    
    var thumbnailImageName: String {
        return "\(id)-thumb"
    }
    
    var locationCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: latitude,
            longitude: longitude)
    }

    var formattedCoordinates: String {
        String(localized: "\(latitude.formatted())\n\(longitude.formatted())",
               comment: "The coordinates of a landmark, consisting of the latitude and longitude")
    }

    var formattedTotalArea: String {
        guard let totalArea else { return "" }
        return totalArea.formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }

    var formattedElevation: String {
        guard let elevation else { return "" }
        switch elevation {
        case .fixed(let elevation):
            return Elevation.formatted(elevation)
        case .openRange(let highElevation):
            return String(localized: "up to \(Elevation.formatted(highElevation))",
                          comment: "The elevation range of a landmark, where only the upper bound is specified (such as '300 m')")
        case .closedRange(let lowElevation, let highElevation):
            return String(localized: "\(lowElevation.value.formatted())–\(Elevation.formatted(highElevation))",
                          comment: "The elevation range of a landmark, where both bounds are specified (such as '100–300 m')")
        }
    }

    var formattedLocation: String {
        guard let location else { return "" }
        return String(localized: location)
    }

    var coordinateRegion: MKCoordinateRegion {
        MKCoordinateRegion(center: locationCoordinate,
                           span: .init(latitudeDelta: span, longitudeDelta: span))
    }
    
    static func == (lhs: Landmark, rhs: Landmark) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation {
            Image($0.thumbnailImageName)
        }
    }

    var sharePreview: SharePreview<Never, Image> {
        SharePreview(name, icon: Image(thumbnailImageName))
    }
}
