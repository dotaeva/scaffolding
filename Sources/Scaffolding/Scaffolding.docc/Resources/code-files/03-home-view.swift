import SwiftUI
import Scaffolding

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("Home")
                .font(.largeTitle)

            Text("Welcome to ScaffoldingDemo")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Home")
    }
}
