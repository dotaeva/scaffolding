import SwiftUI
import Scaffolding

struct DetailView: View {
    @Environment(AppCoordinator.self) private var coordinator

    let title: String

    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.largeTitle)

            Text("This is the detail screen.")
                .foregroundStyle(.secondary)

            Button("Go Back") {
                coordinator.pop()
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle(title)
    }
}
