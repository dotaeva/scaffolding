/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
An enumeration of activities people complete to earn a badge.
*/

import Foundation

/// An enumeration of activities people complete to earn a badge.
enum Activity: String, Identifiable, CaseIterable {
    case takePhoto
    case readDescription
    case findNature
    case drawSketch
    
    var id: String {
        return self.rawValue
    }

    var description: LocalizedStringResource {
        switch self {
        case .takePhoto:
            return LocalizedStringResource("Take a photo",
                                           comment: "Description of an activity that people can select in Activities tab.")
        case .readDescription:
            return LocalizedStringResource("Read the landmark description",
                                           comment: "Description of an activity that people can select in Activities tab.")
        case .findNature:
            return LocalizedStringResource("Find a cool piece of nature",
                                           comment: "Description of an activity that people can select in Activities tab.")
        case .drawSketch:
            return LocalizedStringResource("Draw a sketch of this landmark",
                                           comment: "Description of an activity that people can select in Activities tab.")
        }
    }
}
