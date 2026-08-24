import SwiftUI
import Scaffolding

// MARK: - Factory
// Where each route's screen is actually assembled: views get their
// ViewModels here, child coordinators get their dependencies. The
// route table stays in the class body because @Scaffoldable scans
// only the class declaration — a route in an extension is silently
// untracked — while these `make…` helpers are invisible to it, so
// they need no @ScaffoldingIgnored.

extension TodoDetailCoordinator {
    func makeDetail(todo: Todo) -> some View {
        TodoDetailView(viewModel: TodoDetailViewModel(todo: todo, store: store))
    }

    /// A pushed editor for the long-form notes.
    func makeNotes(todo: Todo) -> some View {
        NotesEditorView(viewModel: TodoDetailViewModel(todo: todo, store: store))
    }

    /// Modal sub-flow returning the chosen tags. Its coordinator opts out
    /// of environment injection, so it is handed to its screen by init.
    func makeTagPicker(selected: [String]) -> any Coordinatable {
        TagPickerCoordinator(selected: selected, tags: store.tags)
    }
}
