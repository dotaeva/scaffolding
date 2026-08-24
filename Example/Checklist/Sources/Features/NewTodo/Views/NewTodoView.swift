import SwiftUI
import Scaffolding

struct NewTodoView: View {
    @Environment(NewTodoCoordinator.self) private var coordinator
    @State var viewModel: NewTodoViewModel

    var body: some View {
        Form {
            Section("Task") {
                TextField("What needs doing?", text: $viewModel.title, axis: .vertical)
            }

            Section("Where") {
                Button {
                    coordinator.chooseList()   // pushes, then awaits the pop
                } label: {
                    HStack {
                        Text("List")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "folder.fill")
                            .foregroundStyle(viewModel.listColor)
                        Text(viewModel.listName)
                            .foregroundStyle(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .buttonStyle(.plain)
                if let picked = viewModel.lastPickedListName {
                    Text("Picker returned: \(picked)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("When") {
                Toggle("Due date", isOn: $viewModel.hasDueDate)
                if viewModel.hasDueDate {
                    DatePicker("Due", selection: $viewModel.dueDate)
                }
            }

            Section("Priority") {
                Picker("Priority", selection: $viewModel.priority) {
                    ForEach(Priority.allCases) { Text($0.name).tag($0) }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            Section("Tags") {
                ForEach(viewModel.allTags, id: \.self) { tag in
                    Toggle(tag, isOn: Binding(
                        get: { viewModel.tags.contains(tag) },
                        set: { _ in viewModel.toggle(tag: tag) }
                    ))
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("New Task")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { coordinator.save() }
                    .disabled(!viewModel.canSave)
            }
        }
    }
}
