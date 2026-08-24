import SwiftUI
import Scaffolding

struct TodayView: View {
    @Environment(TodayCoordinator.self) private var coordinator
    @State var viewModel: TodayViewModel

    var body: some View {
        List {
            Section {
                ProgressView(value: viewModel.progress) {
                    Text("\(Int(viewModel.progress * 100))% of all tasks done")
                        .font(.footnote)
                }
                .padding(.vertical, 4)
            }
            if !viewModel.overdue.isEmpty {
                section("Overdue", todos: viewModel.overdue)
            }
            if !viewModel.later.isEmpty {
                section("Today", todos: viewModel.later)
            }
        }
        .navigationTitle(viewModel.greeting)
        .overlay {
            if viewModel.isEmpty {
                ContentUnavailableView(
                    "Nothing due today",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Add a task or enjoy the quiet.")
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Task", systemImage: "plus") { coordinator.addTodo() }
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Focus Session", systemImage: "moon.stars") {
                    coordinator.startFocusSession()
                }
            }
        }
    }

    private func section(_ title: String, todos: [Todo]) -> some View {
        Section(title) {
            ForEach(todos) { todo in
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
    }
}

#Preview("Today") {
    TodayCoordinator(store: TodoStore()).view
        .environment(TodoStore())
}

#Preview("Today · task pushed") {
    // The seeded initializer starts the flow one screen deep.
    TodayCoordinator(store: TodoStore(), startingAt: SampleData.todos[0]).view
        .environment(TodoStore())
}
