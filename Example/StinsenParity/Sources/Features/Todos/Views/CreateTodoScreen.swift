import SwiftUI
import Scaffolding

struct CreateTodoScreen: View {
    @Environment(CreateTodoCoordinator.self) private var coordinator

    @State private var name = ""
    @FocusState private var isFocused: Bool

    private var isEmpty: Bool {
        name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 18) {
            InfoText("Creating hands the new task back to the awaiting "
                     + "present(_:awaiting:) call. Swiping the sheet away "
                     + "resumes the same call with nil.",
                     symbol: "arrow.uturn.backward.circle.fill")

            RoundedTextField("Task name", text: $name)
                .focused($isFocused)
                .padding(.horizontal, 20)
                .onSubmit { if !isEmpty { coordinator.create(name: name) } }

            RoundedButton("Create") { coordinator.create(name: name) }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .disabled(isEmpty)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 460)
        .frame(maxWidth: .infinity)
        .padding(.top, 20)
        .background(Color.pageBackground)
        .navigationTitle("New task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.cancel() }
            }
        }
        .task { isFocused = true }
    }
}
