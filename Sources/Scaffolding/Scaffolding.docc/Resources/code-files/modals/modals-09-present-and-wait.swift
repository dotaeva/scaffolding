import SwiftUI
import Scaffolding

@Scaffoldable @Observable
final class FavoritesCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<FavoritesCoordinator>(root: .list)

    private(set) var favorites: [String] = []

    private var hasOnboarded = false

    func list() -> some View { FavoritesView() }
    func detail(name: String) -> some View { DetailView(name: name) }
    func picker() -> any Coordinatable { PlanetPickerCoordinator() }
    func onboarding() -> some View { OnboardingScreen() }

    func remove(_ planet: String) {
        favorites.removeAll { $0 == planet }
    }

    /// No result, just "continue once it's gone".
    func showOnboardingIfNeeded() async {
        guard !hasOnboarded else { return }
        await presentAndWait(.onboarding, as: .fullScreenCover)
        hasOnboarded = true
    }

    /// The same shape for a pushed screen: push, resume when it pops.
    func pickTags() async {
        await routeAndWait(to: .detail(name: "Tags"))
    }
}
