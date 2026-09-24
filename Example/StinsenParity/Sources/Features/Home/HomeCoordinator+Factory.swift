import SwiftUI
import Scaffolding

// MARK: - Factory

extension HomeCoordinator {
    func makeHome() -> some View { HomeScreen(store: store) }
}
