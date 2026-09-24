import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign

struct PlanDetailsScreen: View {
    @Environment(PlannerCoordinator.self) private var coordinator
    var body: some View {
        @Bindable var draft = coordinator
        AtlasForm {
            Section("Journey details") {
                LabeledContent("Place", value: coordinator.place.name)
                Stepper(value: $draft.days, in: 1...14) {
                    Text("\(coordinator.days) \(coordinator.days == 1 ? "day" : "days")")
                }.accessibilityIdentifier("planner.days")
            }
            PacePicker(selection: $draft.pace)
            Section {
                Button("Review journey") { coordinator.continuePlanning() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("planner.review")
            } footer: {
                Text("A sample plan, with no bookings or payments.")
            }
        }
        .navigationTitle(coordinator.isEditing ? "Edit journey" : "Plan a journey")
        .modifier(PlannerChrome())
    }
}

private struct PacePicker: View {
    @Binding var selection: TravelPace
    var body: some View {
        Section {
            Picker("Pace", selection: $selection) {
                ForEach(TravelPace.allCases, id: \.self) { pace in
                    Text(pace.rawValue)
                        .fixedSize(horizontal: false, vertical: true)
                        .tag(pace)
                        .accessibilityIdentifier("planner.pace.\(pace == .unhurried ? "unhurried" : pace == .balanced ? "balanced" : "adventurous")")
                }
            }
            #if os(macOS)
            .pickerStyle(.radioGroup)
            #else
            .pickerStyle(.inline)
            #endif
            .accessibilityIdentifier("planner.pace")
        } footer: {
            Text(selection.detail)
        }
    }
}

struct PlanReviewScreen: View {
    @Environment(PlannerCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            Section("Journey details") {
                LabeledContent("Place", value: coordinator.place.name)
                LabeledContent("Time away", value: "\(coordinator.days) \(coordinator.days == 1 ? "day" : "days")")
                LabeledContent("Pace", value: coordinator.pace.rawValue)
            }
            Section {
                Button(coordinator.isEditing ? "Save changes" : "Save journey") { coordinator.finish() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("planner.finish")
            } footer: {
                Text("Find this plan in Saved whenever you need it.")
            }
        }
        .navigationTitle("Review journey")
        .modifier(PlannerChrome())
    }
}

private struct PlannerChrome: ViewModifier {
    @Environment(PlannerCoordinator.self) private var coordinator
    func body(content: Content) -> some View {
        content.modifier(InlineNavigationTitle()).toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { coordinator.dismissCoordinator() }
                    .keyboardShortcut(.cancelAction)
                    .accessibilityIdentifier("planner.cancel")
            }
        }
    }
}
