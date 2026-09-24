import SwiftUI
import Scaffolding

struct PreferencesStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State var viewModel: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 6) {
                Text("Preferences")
                    .font(.title2.bold())
                Text("Both are changeable later in Settings.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 36)

            Spacer()

            // A plain VStack, not a Form: an onboarding page is a fixed
            // amount of content, and a scroll view inside a paged TabView
            // fights the horizontal swipe for the same gesture.
            VStack(spacing: 0) {
                Toggle("Sort by due date", isOn: $viewModel.sortByDueDate)
                Divider()
                Toggle("Show completed tasks", isOn: $viewModel.showsCompleted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .background(Color.raisedBackground, in: .rect(cornerRadius: 12))

            VStack(spacing: 4) {
                Text(viewModel.summary)
                Text("\(viewModel.sampleCount) sample tasks are ready to go.")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 16)

            Spacer()

            // Anchored like the other pages' primary actions, so the three
            // pages read as one flow.
            Button("Continue") { coordinator.showReady() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
