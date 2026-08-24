import SwiftUI
import Scaffolding

struct WelcomeView: View {
    // The nearest coordinator, injected by Scaffolding. Views hold no
    // navigation state — they call the coordinator.
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checklist")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Checklist")
                .font(.largeTitle.bold())
            Text("A Scaffolding sample built from native SwiftUI parts: "
                 + "tabs on iPhone, three columns on iPad and Mac, and "
                 + "coordinators that own every transition.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Spacer()
            Button("Get Started") { coordinator.showPreferences() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .padding(28)
        .navigationTitle("Welcome")
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }
}

#Preview {
    // Preview the coordinator at its real root — the macro synthesises no
    // init(initialRoute:).
    OnboardingCoordinator(store: TodoStore(), onComplete: { }).view
        .environment(TodoStore())
}
