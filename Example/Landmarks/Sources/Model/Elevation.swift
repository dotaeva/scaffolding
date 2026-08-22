/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An enumeration of methods to express elevation for a landmark.
*/

import Foundation

/// An enumeration of methods to express elevation for a landmark.
enum Elevation {
    /// A case that captures a fixed elevation measurement, such as "3,000 meters."
    case fixed(Measurement<UnitLength>)
    /// A case that captures an open range of elevation up to a high measurement, such as "up to 3,000 meters."
    case openRange(high: Measurement<UnitLength>)
    /// A case that captures a closed range of elevation between low and high measurements, such as "between 1,000 and 3,000 meters."
    case closedRange(low: Measurement<UnitLength>, high: Measurement<UnitLength>)
    
    static func formatted(_ elevation: Measurement<UnitLength>) -> String {
        elevation.formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }
}
