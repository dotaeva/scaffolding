import SwiftUI
import Scaffolding

struct ReadyView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56))
                .foregroundStyle(.green)
                .symbolEffect(.bounce, options: .nonRepeating)
            Text("You're set")
                .font(.title.bold())
            Text("Finishing swaps the whole hierarchy at the root — no back "
                 + "button leads here again.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 420)
            Spacer()
            VStack(spacing: 10) {
                Button("Start Using Checklist") { coordinator.finish() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button("Start Over") { coordinator.startOver() }
                    .font(.footnote)
            }
        }
        .padding(28)
        .navigationTitle("Ready")
    }
}
