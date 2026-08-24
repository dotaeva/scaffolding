import SwiftUI
import Scaffolding

/// A pushed screen inside the detail flow — on iPad/Mac that means a push
/// *inside the detail column*, which is exactly what SwiftUI expects a
/// flow in a split column to do.
struct NotesEditorView: View {
    @State var viewModel: TodoDetailViewModel

    var body: some View {
        Form {
            Section {
                TextEditor(text: $viewModel.notes)
                    .frame(minHeight: 180)
                    .font(.body)
            } header: {
                Text("Notes")
            } footer: {
                Text("Edits write straight through to the store, so the "
                     + "detail screen behind this one already shows them.")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Notes")
    }
}
