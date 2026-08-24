import SwiftUI

/// Tag management: native editing affordances — `EditButton`, `onDelete`,
/// and a submit-on-return text field.
struct TagsView: View {
    @State var viewModel: SettingsViewModel

    var body: some View {
        List {
            Section {
                ForEach(viewModel.tags, id: \.self) { tag in
                    LabeledContent(tag) {
                        Text("\(viewModel.usageCount(of: tag)) tasks")
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { viewModel.deleteTags(at: $0) }
            }
            Section("Add") {
                HStack {
                    TextField("New tag", text: $viewModel.newTag)
                        .onSubmit { viewModel.addTag() }
                    Button("Add", action: viewModel.addTag)
                        .disabled(viewModel.newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            #if os(iOS)
            ToolbarItem(placement: .topBarTrailing) { EditButton() }
            #endif
        }
    }
}
