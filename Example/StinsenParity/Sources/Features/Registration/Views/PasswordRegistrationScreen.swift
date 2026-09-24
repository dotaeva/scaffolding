import SwiftUI
import Scaffolding

struct PasswordRegistrationScreen: View {
    @Environment(RegistrationCoordinator.self) private var coordinator

    let username: String

    @State private var password = ""
    @State private var confirmation = ""

    private var canRegister: Bool {
        !password.isEmpty && password == confirmation && !coordinator.isWorking
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InfoText("Step two. Registering calls "
                         + "dismissCoordinator(returning:), which resumes the "
                         + "presenter's await with this user and closes the "
                         + "sheet in the same call.")

                RoundedTextField("Password", text: $password, secure: true)
                RoundedTextField("Password again", text: $confirmation, secure: true)

                if !confirmation.isEmpty && password != confirmation {
                    Text("Passwords don't match.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                RoundedButton("Register") {
                    coordinator.register(username: username, password: password)
                }
                .disabled(!canRegister)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle(username)
        .navigationBarTitleDisplayMode(.inline)
    }
}
