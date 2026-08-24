import Foundation
import Scaffolding

// MARK: - Navigation state restoration
// The whole tree — root, tab selection, split columns, every flow's stack,
// presented modals — is captured as opaque Data and replayed on launch.

extension AppCoordinator {
    private static let stateKey = "navigation-state"

    /// Called when the scene leaves the foreground. Capture walks the tree
    /// from the coordinator it is called on.
    func saveNavigationState() {
        UserDefaults.standard.set(try? captureNavigationState(), forKey: Self.stateKey)
    }

    /// Called once at launch. Restoration *replays* routes through the
    /// ordinary navigation calls; routes that no longer decode are skipped,
    /// so a stale snapshot degrades instead of failing the launch, and
    /// subtrees that don't opt into `codable:` (the new-task sub-flow)
    /// simply restore at their initial position.
    func restoreNavigationState() {
        guard let data = UserDefaults.standard.data(forKey: Self.stateKey) else { return }
        try? restoreNavigationState(from: data)
    }

    func forgetNavigationState() {
        UserDefaults.standard.removeObject(forKey: Self.stateKey)
    }
}
