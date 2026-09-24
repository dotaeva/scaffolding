import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign

struct LabScreen: View {
    var body: some View {
        AtlasForm {
            NavigationExperiments()
            SessionExperiments()
            HierarchySection()
        }
        .navigationTitle("Lab")
    }
}

private struct NavigationExperiments: View {
    @Environment(LabCoordinator.self) private var coordinator
    var body: some View {
        Section("Navigation") {
            Button("Push a screen", systemImage: "arrow.right") { coordinator.pushStep(1) }
                .accessibilityIdentifier("lab.push")
            Button("Await a choice", systemImage: "arrow.triangle.branch") { coordinator.choose() }
                .accessibilityIdentifier("lab.await")
            LabeledContent("Result", value: coordinator.lastResult)
            Button("Plan in full screen", systemImage: "arrow.up.left.and.arrow.down.right") { coordinator.planFullScreen() }
                .accessibilityIdentifier("lab.fullscreen")
            Button("Open a deep link", systemImage: "link") { coordinator.session?.openExampleLink() }
                .accessibilityIdentifier("lab.deeplink")
        }
    }
}

private struct SessionExperiments: View {
    @Environment(LabCoordinator.self) private var coordinator
    var body: some View {
        Section {
            Button("Save navigation", systemImage: "bookmark.circle") { coordinator.session?.saveCheckpoint() }
                .accessibilityIdentifier("lab.checkpoint.save")
            Button("Restore navigation", systemImage: "arrow.counterclockwise") { coordinator.session?.restoreCheckpoint() }
                .disabled(coordinator.session?.hasCheckpoint != true).accessibilityIdentifier("lab.checkpoint.restore")
            if let date = coordinator.session?.checkpointDate {
                LabeledContent("Saved") { Text(date, format: .dateTime.month().day().hour().minute()) }
            }
        } header: {
            Text("Navigation checkpoint")
        } footer: {
            Text("Restores screens, tabs, and layout. Your places and journeys save automatically and stay unchanged.")
        }
        Section {
            Button(coordinator.session?.layout == .tabs ? "Use split view" : "Use tab view", systemImage: "rectangle.split.3x1") {
                coordinator.session?.switchLayout(coordinator.session?.layout == .tabs ? .split : .tabs)
            }.accessibilityIdentifier("lab.layout")
            Button("Replay introduction", systemImage: "arrow.counterclockwise") { coordinator.session?.restartWelcome() }
                .accessibilityIdentifier("lab.welcome")
        } header: {
            Text("App")
        } footer: {
            Text("Changing the layout starts fresh navigation and keeps your collection.")
        }
    }
}

private struct HierarchySection: View {
    @Environment(LabCoordinator.self) private var coordinator
    var body: some View {
        Section {
            ScrollView(.horizontal) {
                Text(coordinator.session?.hierarchyDescription ?? "No session")
                    .monospaced().textSelection(.enabled)
                    .fixedSize(horizontal: true, vertical: false)
            }
        } header: {
            Text("Live coordinator tree")
        } footer: {
            Text("Ten modules, each owning its flow. The Lab uses a capability protocol without importing the app or shell.")
        }
    }
}

struct LabStepScreen: View {
    let number: Int
    @Environment(LabCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            Section("Current flow") {
                LabeledContent("Stack depth", value: coordinator.depth.formatted())
                Text(coordinator.navigationOutcome)
            }
            Section {
                Button("Replace with chapter \(number + 1)") { coordinator.replaceStep(number + 1) }
                Button("Try a distinct push") { coordinator.pushStep(number + 1) }
                Button("Back to the Lab") { coordinator.popToRoot() }.accessibilityIdentifier("lab.root")
            } footer: {
                Text("Replace updates this screen without growing the stack. Distinct skips another request for the same route case.")
            }
        }
        .navigationTitle("Chapter \(number)").modifier(InlineNavigationTitle())
    }
}
