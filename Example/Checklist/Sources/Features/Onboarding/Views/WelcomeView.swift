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
            VStack(spacing: 6) {
                Button("Get Started") { coordinator.showPreferences() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Text("…or swipe")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.groupedBackground.ignoresSafeArea())
    }
}

#Preview {
    // Preview the coordinator at its real root — the macro synthesises no
    // init(initialRoute:).
    OnboardingCoordinator(store: TodoStore(), onComplete: { }).view
        .environment(TodoStore())
}
