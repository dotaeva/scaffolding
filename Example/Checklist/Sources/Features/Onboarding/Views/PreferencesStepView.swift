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
            .padding(.bottom, 12)

            Form {
                Section {
                    Toggle("Sort by due date", isOn: $viewModel.sortByDueDate)
                    Toggle("Show completed tasks", isOn: $viewModel.showsCompleted)
                }
                Section("Preview") {
                    LabeledContent("Sample tasks", value: "\(viewModel.sampleCount)")
                    Text(viewModel.summary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)

            // Anchored like the other pages' primary actions, so the three
            // pages read as one flow.
            Button("Continue") { coordinator.showReady() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, 12)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
