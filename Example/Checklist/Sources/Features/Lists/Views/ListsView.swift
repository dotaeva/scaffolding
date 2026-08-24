import SwiftUI
import Scaffolding

struct ListsView: View {
    @Environment(ListsCoordinator.self) private var coordinator
    @State var viewModel: ListsViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.smartLists) { smart in
                    Button { coordinator.showTasks(in: .smart(smart)) } label: {
                        HStack {
                            Label {
                                Text(smart.name).foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: smart.symbol)
                                    .foregroundStyle(smart.tint)
                            }
                            Spacer()
                            Text("\(viewModel.count(for: smart))")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            Section("My Lists") {
                ForEach(viewModel.lists) { list in
                    Button { coordinator.showTasks(in: .list(list)) } label: {
                        ListRow(
                            list: list,
                            openCount: viewModel.openCount(for: list),
                            progress: viewModel.progress(for: list)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .onDelete { viewModel.delete(at: $0) }
            }
        }
        .navigationTitle("Lists")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New List", systemImage: "folder.badge.plus") {
                    viewModel.isAddingList = true
                }
            }
            #if os(iOS)
            ToolbarItem(placement: .topBarLeading) { EditButton() }
            #endif
        }
        .alert("New List", isPresented: $viewModel.isAddingList) {
            // Single-field prompt: native alert, not a coordinator route.
            TextField("Name", text: $viewModel.newListName)
            Button("Add") { viewModel.addList() }
            Button("Cancel", role: .cancel) { }
        }
    }
}

#Preview {
    ListsCoordinator(store: TodoStore()).view
        .environment(TodoStore())
}
