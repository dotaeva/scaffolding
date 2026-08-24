import SwiftUI
import Scaffolding

/// Receives its coordinator through `init` — the flow opted out of
/// environment injection with `@Scaffoldable(injectsCoordinator: false)`.
struct TagPickerView: View {
    let coordinator: TagPickerCoordinator

    var body: some View {
        List {
            Section {
                ForEach(coordinator.tags, id: \.self) { tag in
                    Button { coordinator.toggle(tag) } label: {
                        HStack {
                            Text(tag)
                                .foregroundStyle(.primary)
                            Spacer()
                            if coordinator.selected.contains(tag) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            } footer: {
                Text("Selecting returns the tags to the awaiting presenter "
                     + "with dismissCoordinator(returning:).")
            }
        }
        .navigationTitle("Tags")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.cancel() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { coordinator.confirm() }
            }
        }
    }
}
