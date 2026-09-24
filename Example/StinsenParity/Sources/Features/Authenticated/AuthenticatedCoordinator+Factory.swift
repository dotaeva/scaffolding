import SwiftUI
import Scaffolding

// MARK: - Factory

extension AuthenticatedCoordinator {
    func makeHome() -> (any Coordinatable, some View) {
        (HomeCoordinator(store: store),
         Label("Home", systemImage: "house"))
    }

    func makeTodos() -> (any Coordinatable, some View) {
        (TodosCoordinator(store: store, toasts: toasts),
         Label("Todos", systemImage: "checklist"))
    }

    func makeProfile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(user: user, store: store),
         Label("Profile", systemImage: "person.crop.circle"))
    }

    func makeTestbed() -> (any Coordinatable, some View) {
        (TestbedCoordinator(toasts: toasts),
         Label("Testbed", systemImage: "bed.double"))
    }
}
