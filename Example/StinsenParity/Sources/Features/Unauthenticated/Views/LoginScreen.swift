import SwiftUI
import Scaffolding

struct LoginScreen: View {
    // The nearest coordinator, injected by Scaffolding. The view holds no
    // navigation state — it calls the coordinator.
    @Environment(UnauthenticatedCoordinator.self) private var coordinator

    // Credentials are this screen's own business, so they stay here.
    @State private var username = "user@example.com"
    @State private var password = "password"

    var body: some View {
        // Centred when it fits, scrollable when the keyboard takes the room.
        GeometryReader { proxy in
            ScrollView {
                VStack(spacing: 22) {
                    hero

                    VStack(spacing: 12) {
                        RoundedTextField("Username", text: $username)
                        RoundedTextField("Password", text: $password, secure: true)
                    }

                    VStack(spacing: 10) {
                        RoundedButton("Login") {
                            coordinator.signIn(username: username, password: password)
                        }
                        .frame(maxWidth: .infinity)

                        HStack(spacing: 18) {
                            Button("Register") { coordinator.showRegistration() }
                            Button("Forgot your password?") { coordinator.showForgotPassword() }
                        }
                        // Plain, not the default: macOS would otherwise draw
                        // two more bordered buttons under the primary one.
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.tint)
                        .font(.subheadline)
                        .padding(.top, 2)
                    }
                    .disabled(coordinator.isWorking)
                }
                // A login form stretched across an iPad reads as a bug,
                // not a layout: cap it and centre it.
                .frame(maxWidth: 380)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.vertical, 40)
                .frame(minHeight: proxy.size.height, alignment: .center)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(Color.pageBackground)
        // The hero *is* the title here; a "Welcome" bar above it only
        // repeats itself. Pushed screens still get their own bar.
        .toolbar(.hidden, for: .navigationBar)
        .overlay { if coordinator.isWorking { ProgressView().controlSize(.large) } }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 74, height: 74)
                .background(AppTheme.tint, in: .rect(cornerRadius: 18))
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)

            VStack(spacing: 5) {
                Text("Scaffolding")
                    .font(.largeTitle.bold())
                Text("The Stinsen sample app, rebuilt. Same screens and flows — "
                     + "but the coordinators are plain @Observable classes and "
                     + "every route is one function.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.bottom, 6)
    }
}

#Preview {
    // Preview the coordinator at its real root — the macro synthesises no
    // init(initialRoute:).
    UnauthenticatedCoordinator(toasts: ToastCenter()).view
}
