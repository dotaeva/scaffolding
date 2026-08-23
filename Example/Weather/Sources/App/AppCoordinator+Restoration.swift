import Foundation
import Scaffolding

// MARK: - Navigation state restoration
// Return the user to where they left off: the whole tree — root, tab
// selection, split columns, every flow's stack, presented modals — is
// captured as opaque Data and replayed onto a fresh tree on launch.

extension AppCoordinator {
    private static let stateKey = "navigation-state"

    /// Called when the scene leaves the foreground. Capture walks the
    /// whole tree from the coordinator it's called on; the Data is opaque.
    func saveNavigationState() {
        UserDefaults.standard.set(try? captureNavigationState(), forKey: Self.stateKey)
    }

    /// Called once at launch. Restoration *replays* routes through the
    /// ordinary navigation calls; routes that no longer decode are skipped,
    /// so a stale snapshot degrades instead of failing the launch.
    /// Subtrees that don't opt into `codable:` (AddLocationCoordinator)
    /// restore at their initial position.
    func restoreNavigationState() {
        guard let data = UserDefaults.standard.data(forKey: Self.stateKey) else { return }
        try? restoreNavigationState(from: data)
        // The main root only ever appears post-onboarding; keep the domain
        // flag in step with the restored navigation.
        if isRoot(.main) {
            store.isOnboarded = true
        }
    }
}
