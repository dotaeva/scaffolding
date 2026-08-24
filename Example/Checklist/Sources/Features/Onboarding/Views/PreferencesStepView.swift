import SwiftUI
import Scaffolding

struct PreferencesStepView: View {
    @Environment(OnboardingCoordinator.self) private var coordinator
    @State var viewModel: OnboardingViewModel

    var body: some View {
        Form {
            Section("Starting Preferences") {
                Toggle("Sort by due date", isOn: $viewModel.sortByDueDate)
                Toggle("Show completed tasks", isOn: $viewModel.showsCompleted)
            }
            Section {
                LabeledContent("Sample tasks", value: "\(viewModel.sampleCount)")
                Text(viewModel.summary)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Preview")
            } footer: {
                Text("Both are changeable later in Settings.")
            }
            Section {
                Button("Continue") { coordinator.showReady() }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Preferences")
    }
}
