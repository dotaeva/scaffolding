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
    }
}
