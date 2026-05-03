// Code samples for /docs (Meet Scaffolding) — mirror DocC's
// MeetScaffolding article + Scaffolding.md.

// Mounting — how a coordinator becomes a SwiftUI scene/view.
export const CODE_MOUNT_APP = `import SwiftUI
import Scaffolding

@main
struct MyApp: App {
    // Hold the root coordinator in @State so SwiftUI keeps it alive
    // for the lifetime of the scene.
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view              // computed property — no parens
        }
    }
}`;

export const CODE_MOUNT_PREVIEW = `#Preview {
    HomeCoordinator().view
}`;

export const CODE_FLOW = `@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: String) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }
}`;

export const CODE_FLOW_NAV = `coordinator.route(to: .detail(item: "Earth"))           // push
coordinator.present(.settings, as: .sheet)              // sheet
coordinator.present(.settings, as: .fullScreenCover)    // full-screen cover

coordinator.pop()
coordinator.popToRoot()
coordinator.popToFirst(.detail)
coordinator.popToLast(.detail)`;

export const CODE_TAB = `@Scaffoldable @Observable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.feed, .profile])

    func feed() -> (any Coordinatable, some View) {
        (FeedCoordinator(), Label("Feed", systemImage: "list.bullet"))
    }

    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
}`;

export const CODE_TAB_API = `coordinator.selectFirstTab(.feed)
coordinator.appendTab(.notifications)
coordinator.removeLastTab(.notifications)`;

export const CODE_ROOT = `@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .splash)

    func splash() -> some View { SplashView() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }
    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
}`;

export const CODE_ROOT_SET = `coordinator.setRoot(.authenticated)`;

export const CODE_ENV = `struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator

    var body: some View {
        Button("Next") {
            coordinator.route(to: .nextScreen)
        }
    }
}`;

export const CODE_ENV_DEST = `@Environment(\\.destination) private var destination

// destination.routeType        → .root, .push, .sheet, or .fullScreenCover
// destination.presentationType → how this view was presented globally
// destination.meta             → which case of Destinations this is`;

// A reusable adaptive top bar. Reads the destination metadata from the
// environment and swaps its leading control depending on how the screen
// was reached — so the same bar renders correctly when the view is a
// root, a pushed detail, or a presented sheet.
export const CODE_ADAPTIVE_BAR = `import SwiftUI
import Scaffolding

/// A top bar that adapts its leading control to how the screen was
/// reached. Drop it into any view managed by a Scaffolding coordinator
/// — \`\\.destination\` is injected automatically for every destination
/// the framework materialises.
struct AdaptiveTopBar: View {
    let title: String

    @Environment(\\.destination) private var destination
    // Scaffolding wraps NavigationStack, so SwiftUI's native dismiss
    // works for both pops (push) and modal dismissals.
    @Environment(\\.dismiss) private var dismiss

    var body: some View {
        HStack {
            switch destination.routeType {
            case .push:
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                }
            case .sheet, .fullScreenCover:
                Button("Close") { dismiss() }
            case .root:
                // The root has no parent control — keep the layout
                // stable with a placeholder of the same width.
                Color.clear.frame(width: 24)
            }

            Spacer()
            Text(title).font(.headline)
            Spacer()

            // Mirror the leading control to keep the title centred.
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}

// Use it from any screen — the same view shows a back chevron when
// pushed and a "Close" when presented as a sheet.
struct DetailView: View {
    let item: Planet
    var body: some View {
        VStack(spacing: 0) {
            AdaptiveTopBar(title: item.name)
            ...
        }
    }
}`;

// Preview gotchas — keep snippets tight, the prose carries the rest.
export const CODE_PREVIEW_BAD = `// ❌ The macro doesn't synthesise an initial-route initialiser.
//    There's no \`init(initialRoute:)\` to seed a non-default starting
//    case from a preview.
#Preview {
    HomeCoordinator(initialRoute: .detail(item: planet)).view
}`;

export const CODE_PREVIEW_OK = `// ✅ Preview the coordinator at its actual root...
#Preview("Coordinator · root") {
    HomeCoordinator().view
}

// ✅ ...or render the leaf view directly and inject what it reads
//    from the environment.
#Preview("DetailView · pushed") {
    DetailView(item: .earth)
        .environment(HomeCoordinator())   // satisfies @Environment(HomeCoordinator.self)
}`;

export const CODE_COMPOSE = `@Scaffoldable @Observable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    var session: AuthToken?

    // A child Coordinatable as a route — the macro requires the return
    // type to be \`any Coordinatable\` (not the concrete type) to recognise
    // it as a coordinator destination. \`present(.login(...))\` then
    // resolves the LoginCoordinator and presents it as a sheet, with
    // the parent set automatically and the result delivered through
    // the \`onComplete\` callback the parent installs at construction time.
    func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
        LoginCoordinator(onComplete: onComplete)
    }

    func startLoginFlow() {
        present(.login(onComplete: { [weak self] token in
            self?.session = token
        }), as: .sheet)
    }
}`;

// Deep linking — chain the typed `<T: Coordinatable>` overloads to
// walk the coordinator tree and seed each layer's state in one go.
export const CODE_DEEPLINK = `// AppCoordinator.swift
//
// Deep-link entry point. From a cold launch (URL, push notification,
// quick action), drive the coordinator tree to the exact target
// state by chaining the typed overloads — each \`<T: Coordinatable>\`
// variant gives you a typed handle on the resolved child once the
// route lands.
@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    /// Open the user's profile from a cold launch.
    func openProfile(userId: Int) {
        // 1. Swap the root to authenticated → returns the new
        //    MainTabCoordinator typed correctly.
        setRoot(.authenticated) { (tab: MainTabCoordinator) in
            // 2. Select the profile tab → typed handle on its
            //    ProfileCoordinator (a FlowCoordinatable).
            tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
                // 3. Push the user-detail screen on the profile flow.
                profile.route(to: .userDetail(id: userId))
            }
        }
    }
}`;

export const CODE_DEEPLINK_URL = `// MyApp.swift — wire the deep link from a URL.
@main
struct MyApp: App {
    @State private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            coordinator.view
                .onOpenURL { url in
                    if let userId = parseUserURL(url) {
                        coordinator.openProfile(userId: userId)
                    }
                }
        }
    }
}`;

export const CODE_CUSTOMIZE = `@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar items */ }
}`;

// Dismissing — nested coordinator flow. Two coordinators: AppCoordinator
// hosts the main flow and presents LoginCoordinator as a sheet.
// LoginCoordinator is itself a flow with two steps (email → password).
// The submit button on the deepest pushed screen calls
// dismissCoordinator() — closing the *entire* sheet, not just the topmost
// step.

export const CODE_DISMISS_PARENT = `@Scaffoldable @Observable
final class AppCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<AppCoordinator>(root: .home)

    var session: AuthToken?

    func home() -> some View { HomeView() }

    // Child coordinator route — return type must be \`any Coordinatable\`
    // for the macro to recognise it as a coordinator destination.
    func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
        LoginCoordinator(onComplete: onComplete)
    }

    func startLogin() {
        present(.login(onComplete: { [weak self] token in
            self?.session = token
        }), as: .sheet)
    }
}`;

export const CODE_DISMISS_CHILD = `@Scaffoldable @Observable
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .email)

    let onComplete: @MainActor (AuthToken) -> Void

    init(onComplete: @escaping @MainActor (AuthToken) -> Void) {
        self.onComplete = onComplete
    }

    func email()                    -> some View { EmailStepView() }
    func password(email: String)    -> some View { PasswordStepView(email: email) }
}`;

export const CODE_DISMISS_VIEWS = `struct EmailStepView: View {
    @Environment(LoginCoordinator.self) private var coordinator
    @State private var email = ""

    var body: some View {
        Form {
            TextField("Email", text: $email)
            Button("Next") {
                coordinator.route(to: .password(email: email))   // push
            }
        }
    }
}

struct PasswordStepView: View {
    @Environment(LoginCoordinator.self) private var coordinator
    let email: String
    @State private var password = ""

    var body: some View {
        Form {
            SecureField("Password", text: $password)
            HStack {
                Button("Back")    { coordinator.pop() }                   // pop ONE screen
                Button("Sign in") {
                    let token = signIn(email: email, password: password)
                    coordinator.onComplete(token)
                    coordinator.dismissCoordinator()                       // close the whole sheet
                }
            }
        }
    }
}`;

// Side-by-side comparison: same three-screen app, two ways. Two flavors
// of the native NavigationStack(path:) approach — the toggle in the
// comparison header switches between them so readers can see how each
// shapes the call site.

export const CODE_NATIVE_VIEW = `// SwiftUI · NavigationStack(path:) · view-hosted

struct ContentView: View {
    @State private var path: [Planet] = []
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List(planets) { planet in
                // The list row is itself the navigation link.
                NavigationLink(value: planet) {
                    Label(planet.name, systemImage: "globe")
                }
            }
            .navigationTitle("Planets")
            .navigationDestination(for: Planet.self) { planet in
                DetailView(item: planet, path: $path)
            }
            .toolbar {
                Button("Settings") { showSettings = true }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct DetailView: View {
    let item: Planet
    @Binding var path: [Planet]
    // Or, instead of holding the path binding, the view can lean on
    // SwiftUI's environment value for dismissal:
    // @Environment(\\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text(item.name).font(.title)
            Button("Back") { path.removeLast() }
            // ...equivalently: Button("Back") { dismiss() }
        }
    }
}`;

export const CODE_NATIVE_ENUM = `// SwiftUI · NavigationStack(path:) · typed-enum

// Central destination type — the path holds heterogeneous routes
// type-safely, but you write the enum and switch yourself.
enum AppRoute: Hashable {
    case detail(Planet)
    // case settings, case profile(User), ... add cases as the app grows.
}

struct ContentView: View {
    @State private var path: [AppRoute] = []
    @State private var showSettings = false

    var body: some View {
        NavigationStack(path: $path) {
            List(planets) { planet in
                Button {
                    path.append(.detail(planet))
                } label: {
                    Label(planet.name, systemImage: "globe")
                }
            }
            .navigationTitle("Planets")
            // One destination handler per route type, with a switch
            // inside it. Every new case grows this method.
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .detail(let planet):
                    DetailView(item: planet, path: $path)
                }
            }
            .toolbar {
                Button("Settings") { showSettings = true }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}

struct DetailView: View {
    let item: Planet
    @Binding var path: [AppRoute]
    // Or: @Environment(\\.dismiss) private var dismiss

    var body: some View {
        VStack {
            Text(item.name).font(.title)
            Button("Back") { path.removeLast() }
        }
    }
}`;

export const CODE_SCAFFOLDING = `// Scaffolding · FlowCoordinatable

@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home()               -> some View         { HomeView() }
    func detail(item: Planet) -> some View         { DetailView(item: item) }
    func settings()           -> any Coordinatable { SettingsCoordinator() }
}

struct HomeView: View {
    @Environment(HomeCoordinator.self) private var coordinator

    var body: some View {
        List(planets) { planet in
            Button {
                coordinator.route(to: .detail(item: planet))
            } label: {
                Label(planet.name, systemImage: "globe")
            }
        }
        .navigationTitle("Planets")
        .toolbar {
            Button("Settings") {
                coordinator.present(.settings, as: .sheet)
            }
        }
    }
}

struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    // Scaffolding uses NavigationStack underneath, so SwiftUI's native
    // environment dismiss still works alongside the coordinator API.
    @Environment(\\.dismiss) private var dismiss
    let item: Planet

    var body: some View {
        VStack {
            Text(item.name).font(.title)
            Button("Back") { coordinator.pop() }
            // ...or equivalently: Button("Back") { dismiss() }
        }
    }
}`;
