import SwiftUI
import Scaffolding

struct EmailScreen: View {
    // Views read the nearest coordinator from @Environment and call methods
    // on it — they never hold navigation state themselves.
    @Environment(LoginCoordinator.self) private var coordinator

    @State private var username = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "building.columns.fill")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Scaffolding Demo")
                .font(.title2.weight(.semibold))
            TextField("you@example.com", text: $username)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(.white.opacity(0.07), in: .rect(cornerRadius: 12))
            Button("Continue") {
                coordinator.continueWith(username: username)
            }
            .buttonStyle(.pill)
            .disabled(username.isEmpty)
            Spacer()
        }
        .padding(.horizontal, 24)
        .background(ScreenBackground())
    }
}

#Preview {
    LoginCoordinator().view
        .preferredColorScheme(.dark)
}
