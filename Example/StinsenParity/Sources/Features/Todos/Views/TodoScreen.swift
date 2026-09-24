import SwiftUI
import Scaffolding

/// One task: pushed onto the Todos flow on iPhone, installed as the split
/// view's detail column on iPad and Mac.
///
/// The readouts are the interesting part — the very same view reports
/// `push` in a stack and `root` in a column, and only the column form has
/// a `column` to name.
struct TodoScreen: View {
    /// Present only when a flow hosts this screen. In a split column there
    /// is no `TodosCoordinator` above it, so the read is optional and the
    /// depth row simply disappears.
    @Environment(TodosCoordinator.self) private var flow: TodosCoordinator?
    // Set by the framework when the destination was materialised, so the
    // screen can describe how it was reached.
    @Environment(\.destination) private var destination

    let store: TodosStore
    let id: UUID
    var onToggleFavorite: (UUID) -> Void = { _ in }

    private var todo: Todo? { store[id] }

    var body: some View {
        Group {
            if let todo {
                DetailForm {
                    Section {
                        LabeledContent("Task", value: todo.name)
                        // A toggle, not a button: it reports state as well
                        // as changing it, which a row that only acts cannot.
                        Toggle("Show on Home", isOn: Binding(
                            get: { todo.isFavorite },
                            set: { _ in onToggleFavorite(todo.id) }
                        ))
                    }

                    Section {
                        ReadoutRow("routeType", caseLabel(destination.routeType))
                        if let column = destination.column {
                            ReadoutRow("column", caseLabel(column))
                        }
                        if let flow {
                            ReadoutRow("flow depth", "\(flow.depth)")
                        }
                    } header: {
                        Text("This screen")
                    } footer: {
                        Text("Reached by route(to: .todo(id:)) from a stack, or by "
                             + "setDetail(.todo(id:)) replacing a column. Same "
                             + "screen either way — these rows are the only "
                             + "difference.")
                    }
                }
            } else {
                ContentUnavailableView("Task deleted", systemImage: "trash")
            }
        }
        .navigationTitle("Task")
        .navigationBarTitleDisplayMode(.inline)
    }
}
