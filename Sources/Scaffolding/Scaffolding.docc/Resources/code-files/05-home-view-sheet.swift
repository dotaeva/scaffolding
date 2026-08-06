import SwiftUI
import Scaffolding

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    let items = ["Mercury", "Venus", "Earth", "Mars"]

    var body: some View {
        List(items, id: \.self) { item in
            Button {
                coordinator.route(to: .detail(title: item))
            } label: {
                Label(item, systemImage: "globe")
            }
        }
        .navigationTitle("Planets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // The presenter picks the chrome: route(to:) always
                    // pushes, present(_:as:) handles modals.
                    coordinator.present(.settings, as: .sheet(detents: [.medium, .large]))
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}
