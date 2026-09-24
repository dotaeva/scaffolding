import SwiftUI
import Scaffolding

struct UserRegistrationScreen: View {
    @Environment(RegistrationCoordinator.self) private var coordinator

    @State private var username = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InfoText("Step one of a presented sub-flow. The sheet has its "
                         + "own stack, so this pushes normally inside it.")

                RoundedTextField("Desired username", text: $username)

                RoundedButton("Next step") {
                    coordinator.chooseUsername(username)
                }
                .disabled(username.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle("Register")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.cancel() }
            }
        }
    }
}
