import SwiftUI
import Scaffolding

extension AppRootCoordinator {
    func handle(_ url: URL) {
        // Never deep-link past authentication: isRoot compares by Meta.
        guard isRoot(.main) else {
            pendingURL = url      // replay it after signIn()
            return
        }

        switch url.host() {
        case "planet":
            let name = url.lastPathComponent
            let tabs = setRoot(.main, expecting: AppCoordinator.self)
            let planets = tabs?.selectFirstTab(.planets, expecting: PlanetsCoordinator.self)
            // Land on a predictable stack: clear whatever the user had
            // pushed before pushing the target screen.
            planets?.popToRoot()
            planets?.route(to: .detail(name: name), policy: .distinct)

        case "favorites":
            let tabs = setRoot(.main, expecting: AppCoordinator.self)
            tabs?.selectFirstTab(.favorites)

        default:
            break
        }
    }
}
