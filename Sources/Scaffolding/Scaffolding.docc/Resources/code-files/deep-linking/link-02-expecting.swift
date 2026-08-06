import SwiftUI
import Scaffolding

extension AppRootCoordinator {
    /// planets://planet/Mars
    func handle(_ url: URL) {
        guard url.host() == "planet" else { return }
        let name = url.lastPathComponent

        // Each step resolves the next child and returns it, typed. setRoot
        // re-runs the route function, so the tree is rebuilt — exactly what
        // a cold launch needs.
        let tabs = setRoot(.main, expecting: AppCoordinator.self)
        let planets = tabs?.selectFirstTab(.planets, expecting: PlanetsCoordinator.self)
        planets?.route(to: .detail(name: name))
    }
}
