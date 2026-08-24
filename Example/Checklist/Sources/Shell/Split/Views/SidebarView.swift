import SwiftUI
import Scaffolding

/// The split view's first column. Selection *highlight* is native `List`
/// state; which column content follows is the coordinator's business.
struct SidebarView: View {
    @Environment(MainSplitCoordinator.self) private var coordinator
    @State var viewModel: SidebarViewModel

    var body: some View {
        List(selection: selection) {
            Section {
                ForEach(viewModel.smartLists) { smart in
                    Label(smart.name, systemImage: smart.symbol)
                        .foregroundStyle(.primary)
                        .badge(viewModel.count(for: smart))
                        .tag(TaskSource.smart(smart))
                }
            }
            Section("My Lists") {
                ForEach(viewModel.lists) { list in
                    Label(list.name, systemImage: list.symbol)
                        .badge(viewModel.count(for: list))
                        .tag(TaskSource.list(list))
                        .contextMenu {
                            Button("Delete List", systemImage: "trash", role: .destructive) {
                                viewModel.pendingDeletion = list
                            }
                        }
                }
            }
        }
        .navigationTitle("Checklist")
        .toolbar { toolbar }
        .alert("New List", isPresented: $viewModel.isAddingList) {
            // A single-field prompt is a native alert, not a coordinator
            // destination — the decision tree keeps view-only modals native.
            TextField("Name", text: $viewModel.newListName)
            Button("Add") { viewModel.confirmAddList() }
            Button("Cancel", role: .cancel) { }
        }
        .confirmationDialog(
            "Delete “\(viewModel.pendingDeletion?.name ?? "")”?",
            isPresented: deletionBinding,
            titleVisibility: .visible
        ) {
            Button("Delete List and Tasks", role: .destructive) {
                if let list = viewModel.pendingDeletion { viewModel.delete(list) }
            }
        }
    }

    private var selection: Binding<TaskSource?> {
        Binding(
            get: { coordinator.selectedSource },
            set: { if let source = $0 { coordinator.select(source: source) } }
        )
    }

    private var deletionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.pendingDeletion != nil },
            set: { if !$0 { viewModel.pendingDeletion = nil } }
        )
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button("New List", systemImage: "folder.badge.plus") {
                viewModel.isAddingList = true
            }
        }
        ToolbarItem(placement: .automatic) {
            Button("Settings", systemImage: "gearshape") {
                coordinator.showSettings()   // the tab flow, as a sheet
            }
        }
    }
}
