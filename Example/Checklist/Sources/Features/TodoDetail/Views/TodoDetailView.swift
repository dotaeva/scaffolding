import SwiftUI
import Scaffolding

/// The task editor: a plain native `Form`. Bindings write through the
/// ViewModel to the store, so the list behind it updates live.
struct TodoDetailView: View {
    @Environment(TodoDetailCoordinator.self) private var coordinator
    @State var viewModel: TodoDetailViewModel

    @State private var isConfirmingDelete = false

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $viewModel.title, axis: .vertical)
                    .font(.headline)
                Toggle("Completed", isOn: $viewModel.isDone)
                Toggle("Flagged", isOn: $viewModel.isFlagged)
            }

            Section("Schedule") {
                Toggle("Due date", isOn: $viewModel.hasDueDate)
                if viewModel.hasDueDate {
                    DatePicker("Due", selection: $viewModel.dueDate)
                }
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(Priority.allCases) { priority in
                        Text(priority.name).tag(priority)
                    }
                }
                .pickerStyle(.menu)
            }

            Section("Details") {
                HStack {
                    Text("List")
                    Spacer()
                    Image(systemName: "folder.fill")
                        .foregroundStyle(viewModel.listColor)
                    Text(viewModel.listName)
                        .foregroundStyle(.secondary)
                }
                TodoTagsRow(tags: viewModel.todo.tags) {
                    coordinator.pickTags(for: viewModel.todo)
                }
                Button("Notes…") { coordinator.editNotes(for: viewModel.todo) }
            }

            Section {
                Button("Next Task in List") { coordinator.showNext(after: viewModel.todo) }
                Button("Delete Task", role: .destructive) { isConfirmingDelete = true }
            }
        }
        .formStyle(.grouped)
        #if os(iOS)
        .contentMargins(.bottom, 24, for: .scrollContent)
        #endif
        .navigationTitle(viewModel.todo.title.nilIfEmpty ?? "Task")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .confirmationDialog("Delete this task?", isPresented: $isConfirmingDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                viewModel.delete()
                // The task is gone, so the screen showing it goes too.
                coordinator.dismissCoordinator()
            }
        }
    }
}
