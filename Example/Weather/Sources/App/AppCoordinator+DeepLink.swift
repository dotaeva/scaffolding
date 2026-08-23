import Foundation
import Scaffolding

// MARK: - Deep links
// weather://location/tokyo · weather://day/3

extension AppCoordinator {
    func handle(_ url: URL) {
        // isRoot compares by Meta — don't deep-link past onboarding.
        guard isRoot(.main) else { return }

        switch url.host() {
        case "location":
            guard let location = store.location(id: url.lastPathComponent) else { return }
            store.add(location)
            open(location)
        case "day":
            guard let index = Int(url.lastPathComponent), (0..<10).contains(index) else { return }
            openDay(index, of: store.primary)
        default:
            break
        }
    }

    /// Walks the tree with the typed trailing-closure overloads: each step
    /// resolves the child and hands it over. setRoot re-runs the route
    /// function — the main tree is rebuilt, the cold-launch pattern.
    private func open(_ location: Location) {
        switch layout {
        case .tabs:
            setRoot(.main) { (tabs: MainTabCoordinator) in
                tabs.openLocation(location)
            }
        case .split:
            setRoot(.main) { (split: WeatherSplitCoordinator) in
                split.select(location)
            }
        }
    }

    /// The same walk with the expecting: variants — flatter, and easy to
    /// branch mid-chain.
    private func openDay(_ index: Int, of location: Location) {
        let day = ForecastEngine.day(at: index, seed: location.seed)
        switch layout {
        case .tabs:
            let tabs = setRoot(.main, expecting: MainTabCoordinator.self)
            let forecast = tabs?.selectFirstTab(.weather, expecting: ForecastCoordinator.self)
            forecast?.open(day)
        case .split:
            let split = setRoot(.main, expecting: WeatherSplitCoordinator.self)
            split?.select(location)
            let forecast = split?.setDetail(.forecast(location: location), expecting: ForecastCoordinator.self)
            forecast?.open(day)
        }
    }
}
