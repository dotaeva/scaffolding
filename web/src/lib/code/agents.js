// Code samples for /docs/agents — mirror AGENTS.md verbatim.

export const CODE_NESTED_BAD = `// ❌ Wrong — nested NavigationStack breaks routing.
func detail(item: Item) -> some View {
    NavigationStack {       // ← don't.
        DetailRoot(item: item)
    }
}

// ✅ Right — child FlowCoordinator gets its own NavigationStack at the
//    coordinator boundary, where SwiftUI handles it correctly.
func detail(item: Item) -> any Coordinatable {
    DetailCoordinator(item: item)
}`;

export const CODE_DECISION_TREE = `Is it a push/pop on the current stack?
├─ Yes → coordinator.route(to: .someDestination)
│
└─ No, it's a modal.
   │
   Is the modal a single screen — confirmation, info dialog,
   simple form, picker?
   │
   ├─ Yes → SwiftUI native: .sheet(item:) / .fullScreenCover(item:)
   │
   └─ No, the modal contains its own navigation flow
      (multiple steps, push, dismiss-with-result, etc.).
      │
      → coordinator.present(.flow, as: .sheet)
        (returns a child coordinator from the route function)`;

export const CODE_ANATOMY = `@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    // Required: the observable container that owns the stack.
    var stack = FlowStack<HomeCoordinator>(root: .home)

    // Routes — each becomes a \`Destinations\` enum case.
    func home()             -> some View         { HomeView() }
    func detail(item: Item) -> some View         { DetailView(item: item) }
    func settings()         -> any Coordinatable { SettingsCoordinator() }

    // Optional helpers (regular methods, not auto-generated).
    func openDetail(_ item: Item) {
        route(to: .detail(item: item))
    }
}`;

export const CODE_CONCRETE_VS_EXISTENTIAL = `// ❌ Won't be picked up — concrete type.
func login() -> LoginCoordinator { LoginCoordinator() }

// ✅ Existential — macro generates a \`.login\` case.
func login() -> any Coordinatable { LoginCoordinator() }`;

export const CODE_IGNORED = `@ScaffoldingIgnored
func customize(_ view: AnyView) -> some View {
    view
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { /* shared toolbar */ }
}`;

export const CODE_HIERARCHY = `AppCoordinator (Root)
├── LoginCoordinator (Flow)              ← unauthenticated
└── MainTabCoordinator (Tab)             ← authenticated
    ├── HomeCoordinator (Flow)
    │   └── DetailView (push) + SettingsCoordinator (modal)
    └── ProfileCoordinator (Flow)
        └── EditProfileView (push)`;

export const CODE_RESULT_PRESENTER = `// AppCoordinator
func login(onComplete: @escaping @MainActor (AuthToken) -> Void) -> any Coordinatable {
    LoginCoordinator(onComplete: onComplete)
}

func startLogin() {
    present(.login(onComplete: { [weak self] token in
        self?.session = token
    }), as: .sheet)
}`;

export const CODE_RESULT_PRESENTED = `func submit() {
    onComplete(AuthToken(...))    // deliver result
    dismissCoordinator()          // dismiss self
}`;

export const CODE_PATTERN_SHEET_FLOW = `@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home() -> some View { HomeView() }
    func detail(item: Item) -> some View { DetailView(item: item) }
    func settings() -> any Coordinatable { SettingsCoordinator() }

    func openSettings() {
        present(.settings, as: .sheet)
    }
}`;

export const CODE_PATTERN_NATIVE_SHEET = `// Coordinator: no \`.confirmation\` route — that's an internal view detail.
@MainActor @Observable @Scaffoldable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)
    func home() -> some View { HomeView() }
}

// View: native sheet + local \`@State\`. The confirmation isn't a flow,
// it's a single screen — keep it native.
struct HomeView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    @State private var pendingDelete: Item?

    var body: some View {
        List(items) { item in
            Button(item.name) { pendingDelete = item }
        }
        .sheet(item: $pendingDelete) { item in
            ConfirmDeleteSheet(item: item) {
                /* perform delete */
            }
        }
    }
}`;

export const CODE_PATTERN_AUTH = `@MainActor @Observable @Scaffoldable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    func signIn()  { setRoot(.authenticated) }
    func signOut() { setRoot(.unauthenticated) }
}`;

export const CODE_PATTERN_TAB = `@MainActor @Observable @Scaffoldable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])

    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
}`;

export const CODE_DEEPLINK = `@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }

    /// Land on the user's profile from a URL / push / quick action.
    /// Each \`<T: Coordinatable>\` overload hands the next step a typed
    /// reference to the freshly-resolved child.
    func openProfile(userId: Int) {
        setRoot(.authenticated) { (tab: MainTabCoordinator) in
            tab.selectFirstTab(.profile) { (profile: ProfileCoordinator) in
                profile.route(to: .userDetail(id: userId))
            }
        }
    }
}`;

export const CODE_DEEPLINK_URL = `WindowGroup {
    coordinator.view
        .onOpenURL { url in
            if let userId = parseUserURL(url) {
                coordinator.openProfile(userId: userId)
            }
        }
}`;

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

export const CODE_ADAPTIVE_BAR = `import SwiftUI
import Scaffolding

/// Reusable top bar that adapts to how the current screen was reached.
/// Reads the routing metadata Scaffolding injects automatically into
/// every materialised destination via \`\\.destination\`.
struct AdaptiveTopBar: View {
    let title: String

    @Environment(\\.destination) private var destination
    @Environment(\\.dismiss)     private var dismiss

    var body: some View {
        HStack {
            switch destination.routeType {
            case .push:
                Button { dismiss() } label: { Image(systemName: "chevron.left") }
            case .sheet, .fullScreenCover:
                Button("Close") { dismiss() }
            case .root:
                Color.clear.frame(width: 24)
            }
            Spacer()
            Text(title).font(.headline)
            Spacer()
            Color.clear.frame(width: 24, height: 1)
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
    }
}`;

export const CODE_MISTAKE_NESTED = `// ❌ Breaks \`route(to:)\` from the parent flow.
func detail(item: Item) -> some View {
    NavigationStack {
        DetailScreen(item: item)
    }
}`;

export const CODE_MISTAKE_CONCRETE = `// ❌ Macro skips this — it doesn't recognise concrete types as routes.
func login() -> LoginCoordinator { LoginCoordinator() }`;

export const CODE_MISTAKE_VIEW_STATE = `// ❌ Defeats the point of coordinators.
struct HomeView: View {
    @State private var pushedDetail: Item?
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            List(...)
                .navigationDestination(item: $pushedDetail) { ... }
                .sheet(isPresented: $showSettings) { ... }
        }
    }
}`;

export const CODE_MISTAKE_OLD_API = `// ❌ Old, no longer exists.
coordinator.route(to: .settings, as: .sheet)

// ✅ Correct.
coordinator.present(.settings, as: .sheet)`;

export const CODE_MISTAKE_NAVLINK = `// ❌ Couples the row to navigation; breaks under modular coordinators.
NavigationLink(value: planet) { Label(planet.name, ...) }

// ✅ Plain Button + coordinator call.
Button {
    coordinator.route(to: .detail(item: planet))
} label: {
    Label(planet.name, ...)
}`;

export const CODE_MISTAKE_DISMISS = `// ❌ Dismisses the entire coordinator, not just the current screen.
struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    var body: some View {
        Button("Back") { coordinator.dismissCoordinator() }
    }
}`;
