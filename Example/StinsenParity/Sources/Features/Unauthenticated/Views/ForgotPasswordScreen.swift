import SwiftUI
import Scaffolding

struct ForgotPasswordScreen: View {
    @Environment(UnauthenticatedCoordinator.self) private var coordinator

    @State private var username = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                InfoText("Forgot your password? Enter your username and we'll "
                         + "pretend to send it. Sending pops the flow back to "
                         + "the root with popToRoot() and reports the outcome "
                         + "as a toast.")

                RoundedTextField("Username", text: $username)

                RoundedButton("Send reset link") {
                    coordinator.sendPasswordReset(to: username)
                }
                .disabled(coordinator.isWorking || username.isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 12)
        }
        .navigationTitle("Forgot password")
        .navigationBarTitleDisplayMode(.inline)
    }
}
