/*
See the LICENSE.txt file for this sample's licensing information.

Abstract:
A class that tracks progress toward earning a badge.
*/

import Foundation

/// A class that tracks progress toward earning a badge.
@MainActor
@Observable
class BadgeProgress {
    private var progress: [Activity: Bool] = [
        .takePhoto: false,
        .readDescription: false,
        .findNature: false,
        .drawSketch: false
    ]
    
    init(progress: [Activity: Bool]) {
        self.progress = progress
    }
    
    func isCompleted(_ activity: Activity) -> Bool {
        progress[activity] ?? false
    }
    
    var activities: [Activity] {
        return Array(progress.keys)
    }
    
    var earned: Bool {
        return progress.values.allSatisfy({ $0 == true })
    }
    
    func add(_ activity: Activity) {
        progress[activity] = true
    }
    
    func remove(_ activity: Activity) {
        progress[activity] = false
    }
}
