// Code samples for /docs/tutorial — the six-step Scaffolding walkthrough.

export const CODE_APP_INITIAL = `import SwiftUI

@main
struct ScaffoldingDemoApp: App {
    var body: some Scene {
        WindowGroup {
            Text("Coming soon")
        }
    }
}`;

export const CODE_COORD_EMPTY = `import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)
}`;

export const CODE_COORD_HOME = `@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home() -> some View { Text("Home") }
}`;

export const CODE_COORD_DETAIL = `@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home()              -> some View { Text("Home") }
    func detail(title: String) -> some View { Text(title) }
}`;

export const CODE_COORD_SETTINGS = `@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home()                -> some View { Text("Home") }
    func detail(title: String) -> some View { Text(title) }
    func settings()            -> some View { Text("Settings") }
}`;

export const CODE_HOME_VIEW = `import SwiftUI
import Scaffolding

struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Text("Hello, \\(String(describing: coordinator))")
    }
}`;

export const CODE_DETAIL_VIEW = `struct DetailView: View {
    let title: String
    var body: some View { Text(title).font(.title) }
}`;

export const CODE_SETTINGS_VIEW = `struct SettingsView: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        Form {
            Button("Done") {
                coordinator.pop()
            }
        }
        .navigationTitle("Settings")
    }
}`;

export const CODE_HOME_NAV = `struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let items = ["Mercury", "Venus", "Earth", "Mars"]

    var body: some View {
        List(items, id: \\.self) { item in
            Button {
                coordinator.route(to: .detail(title: item))
            } label: {
                Label(item, systemImage: "globe")
            }
        }
        .navigationTitle("Planets")
    }
}`;

export const CODE_DETAIL_NAV = `struct DetailView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let title: String

    var body: some View {
        VStack {
            Text(title).font(.title)
            // @Environment(\\.dismiss) works here too.
            Button("Go Back") { coordinator.pop() }
        }
    }
}`;

export const CODE_COORD_FINAL = `@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    func home()                -> some View { HomeView() }
    func detail(title: String) -> some View { DetailView(title: title) }
    func settings()            -> some View {
        NavigationStack { SettingsView() }
    }
}`;

export const CODE_HOME_SHEET = `struct HomeView: View {
    @Environment(AppCoordinator.self) private var coordinator
    let items = ["Mercury", "Venus", "Earth", "Mars"]

    var body: some View {
        List(items, id: \\.self) { item in
            Button {
                coordinator.route(to: .detail(title: item))
            } label: { Label(item, systemImage: "globe") }
        }
        .navigationTitle("Planets")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    coordinator.present(.settings, as: .sheet)
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
    }
}`;

export const CODE_APP_FINAL = `import SwiftUI

@main
struct ScaffoldingDemoApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view
        }
    }
}`;
