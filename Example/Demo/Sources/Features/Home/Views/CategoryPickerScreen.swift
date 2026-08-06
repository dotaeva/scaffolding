import SwiftUI
import Scaffolding

struct CategoryPickerScreen: View {
    @Environment(HomeCoordinator.self) private var coordinator

    var body: some View {
        List {
            Button("All categories") { choose(nil) }
            ForEach(Transaction.categories, id: \.self) { category in
                Button(category) { choose(category) }
            }
        }
        .scrollEdgeEffectStyle(.soft, for: .top)
        .scrollContentBackground(.hidden)
        .background(ScreenBackground())
        .navigationTitle("Category")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func choose(_ category: String?) {
        coordinator.category = category
        // Popping resumes the routeAndWait continuation in pickCategory().
        coordinator.pop()
    }
}
