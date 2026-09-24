import SwiftUI
import Scaffolding

/// A one-screen sub-flow whose whole job is returning a `Todo`.
///
/// It knows nothing about who presented it: the value goes back through
/// `dismissCoordinator(returning:)`, and the presenter is the one
/// awaiting it.
@MainActor
@Observable
@Scaffoldable
final class CreateTodoCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<CreateTodoCoordinator>(root: .create)

    // MARK: Routes

    func create() -> some View { makeCreate() }
}

// MARK: - Factory

extension CreateTodoCoordinator {
    func makeCreate() -> some View { CreateTodoScreen() }
}

// MARK: - Result

extension CreateTodoCoordinator {
    func create(name: String) {
        dismissCoordinator(returning: Todo(name: name))
    }

    /// Resumes the presenter's await with `nil`.
    func cancel() {
        dismissCoordinator()
    }
}

// MARK: - Presented content

extension CreateTodoCoordinator {
    func customize(_ view: AnyView) -> some View {
        view.presentationDetents([.medium])
    }
}
