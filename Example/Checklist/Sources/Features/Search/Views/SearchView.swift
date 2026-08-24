import SwiftUI
import Scaffolding

struct SearchView: View {
    @Environment(SearchCoordinator.self) private var coordinator
    @State var viewModel: SearchViewModel

    var body: some View {
        List {
            ForEach(viewModel.results) { todo in
                Button { coordinator.open(todo) } label: {
                    TodoRow(todo: todo, listName: viewModel.listName(for: todo)) {
                        viewModel.toggleDone(todo)
                    }
                }
                .buttonStyle(.plain)
                .todoRowActions(
                    for: todo,
                    toggleDone: { viewModel.toggleDone(todo) },
                    toggleFlag: { viewModel.toggleFlag(todo) },
                    delete: { viewModel.delete(todo) }
                )
            }
        }
        .navigationTitle("Search")
        #if os(iOS)
        // iOS 26 floats the search field over the bottom of the screen —
        // inset the scroll content so the last row stays readable.
        .contentMargins(.bottom, 52, for: .scrollContent)
        .textInputAutocapitalization(.never)
        #endif
        // Native search chrome: the field and its scopes are system UI.
        .searchable(text: $viewModel.query, prompt: "Tasks, notes, tags")
        .searchScopes($viewModel.scope) {
            ForEach(SearchViewModel.Scope.allCases) { scope in
                Text(scope.name).tag(scope)
            }
        }
        .overlay {
            if viewModel.results.isEmpty {
                ContentUnavailableView.search(text: viewModel.query)
            }
        }
    }
}

#Preview {
    SearchCoordinator(store: TodoStore()).view
        .environment(TodoStore())
}
