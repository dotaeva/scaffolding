import SwiftUI
import Scaffolding

/// Pushed by `chooseList()`, which suspends in `routeAndWait` until this
/// screen leaves the stack. Picking writes the draft and pops; backing out
/// without choosing resumes the caller just the same.
struct ListPickerView: View {
    @Environment(NewTodoCoordinator.self) private var coordinator
    @State var viewModel: NewTodoViewModel

    var body: some View {
        List(viewModel.lists) { list in
            Button {
                viewModel.select(list: list)
                coordinator.pop()
            } label: {
                HStack {
                    Label(list.name, systemImage: list.symbol)
                        .foregroundStyle(list.color)
                    Spacer()
                    if viewModel.listID == list.id {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.tint)
                    }
                }
            }
        }
        .navigationTitle("Choose List")
    }
}
