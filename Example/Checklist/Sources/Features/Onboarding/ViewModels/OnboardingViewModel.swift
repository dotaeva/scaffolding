import SwiftUI
import Observation

/// The one onboarding step with state worth a ViewModel: the starting
/// preferences. Welcome and Ready are static, so they get none — an empty
/// ViewModel would be ceremony, not architecture.
@MainActor
@Observable
final class OnboardingViewModel {
    private let store: TodoStore

    init(store: TodoStore) {
        self.store = store
    }

    var sortByDueDate: Bool {
        get { store.sortByDueDate }
        set { store.sortByDueDate = newValue }
    }

    var showsCompleted: Bool {
        get { store.showsCompleted }
        set { store.showsCompleted = newValue }
    }

    var summary: String {
        let sort = sortByDueDate ? "due date" : "priority"
        let completed = showsCompleted ? "shown" : "hidden"
        return "Sorted by \(sort), completed tasks \(completed)."
    }

    var sampleCount: Int { store.todos.count }
}
