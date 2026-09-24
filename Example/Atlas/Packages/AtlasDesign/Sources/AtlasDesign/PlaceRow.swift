import SwiftUI
import AtlasDomain

public struct PlaceRow: View {
    private let place: Place
    public init(place: Place) { self.place = place }

    public var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(place.name).font(.headline)
                Text(place.region).font(.subheadline).foregroundStyle(.secondary)
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
        } icon: {
            Image(systemName: symbol).foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .contentShape(.rect)
    }

    private var symbol: String {
        switch place.landscape {
        case .alpine: "mountain.2"
        case .garden: "leaf"
        case .coast: "water.waves"
        }
    }
}
