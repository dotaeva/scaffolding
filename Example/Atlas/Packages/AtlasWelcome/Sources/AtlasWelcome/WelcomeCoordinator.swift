import SwiftUI
import Scaffolding
import AtlasDomain
import AtlasDesign

@MainActor @Observable @Scaffoldable(codable: true)
public final class WelcomeCoordinator: FlowCoordinatable {
    public var stack = FlowStack<WelcomeCoordinator>(root: .welcome)
    private weak var session: (any AtlasSessionActions)?

    public init(session: any AtlasSessionActions) { self.session = session }
    func welcome() -> some View { WelcomeScreen() }
    func about() -> some View { AboutScreen() }
    public func begin() { session?.startExploring() }
}

struct WelcomeScreen: View {
    @Environment(WelcomeCoordinator.self) private var coordinator
    var body: some View {
        AtlasForm {
            Section("Scaffolding demo") {
                Text("Explore places, save a journey, and try the navigation that connects ten independent Swift modules.")
            }
            Section("Explore the demo") {
                Label("Discover places and save favorites", systemImage: "map")
                Label("Plan a journey in a separate flow", systemImage: "suitcase.rolling")
                Label("Try deep links and restoration in the Lab", systemImage: "square.stack.3d.up")
            }
            Section {
                Button("Start exploring") { coordinator.begin() }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("welcome.begin")
                Button("About this demo", systemImage: "info.circle") { coordinator.route(to: .about) }
            }
        }
        .navigationTitle("Atlas")
    }
}

struct AboutScreen: View {
    var body: some View {
        AtlasForm {
            Section("About Atlas") {
                Text("An offline demo built with Scaffolding. Each feature is a separate Swift module, exposing its coordinator while keeping its screens internal.")
            }
            Section("Module boundaries") {
                Label("Welcome and app shell", systemImage: "app.connected.to.app.below.fill")
                Label("Discover, Saved, and Places", systemImage: "map")
                Label("Planner and result delivery", systemImage: "suitcase.rolling")
                Label("Navigation experiments in the Lab", systemImage: "square.stack.3d.up")
            }
        }
        .navigationTitle("About Atlas").modifier(InlineNavigationTitle())
    }
}
