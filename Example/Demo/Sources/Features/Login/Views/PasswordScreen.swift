import SwiftUI
import Scaffolding

struct PasswordScreen: View {
    @Environment(LoginCoordinator.self) private var coordinator

    let username: String
    @State private var password = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Welcome, \(username)")
                .font(.title3.weight(.semibold))
            SecureField("Password", text: $password)
                .padding(14)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 12))
            Button("Sign in") {
                coordinator.submit()
            }
            .buttonStyle(.pill)
            .disabled(password.isEmpty)
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(ScreenBackground())
        // No back handling here: this screen was pushed, so the flow's
        // NavigationStack provides the back button.
    }
}

// Leaf view rendered alone: inject the coordinator it reads from
// @Environment.
#Preview {
    PasswordScreen(username: "demo")
        .environment(LoginCoordinator())
        .preferredColorScheme(.dark)
}
