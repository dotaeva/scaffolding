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
                Button { coordinator.startOver() } label: {
                    // A tappable target, not a 16pt line of text.
                    Text("Start Over")
                        .font(.footnote)
                        .frame(minWidth: 44, minHeight: 44)
                        .padding(.horizontal, 16)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.tint)
            }
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
