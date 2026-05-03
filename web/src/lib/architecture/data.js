// Static graph data for the landing-page Architecture diagram.
//
// `NODES`  — coordinator/screen layout in a 1100×600 viewBox (no two
//             boxes overlap and edges have room to curve cleanly).
// `EDGES`  — directed parent → child links between nodes, labelled with
//             the API kind (`setRoot`, `tab`, `push`, `present`).
// `CODE`   — Swift source displayed in the IDE-style aside when a node
//             is selected (mirrors the actual API surface of each kind).
// `PARENT` — child → parent map derived once from `EDGES`.
// `VBW` / `VBH` — diagram viewBox dimensions; shared with the absolutely
//                  positioned HTML node buttons.

export const VBW = 1100;
export const VBH = 600;

export const NODES = {
  app: {
    x: 550, y: 85, w: 320, h: 86,
    kind: 'Root',
    short: 'App',
    title: 'AppCoordinator',
    subtitle: 'Auth ↔ Main',
    file: 'AppCoordinator.swift'
  },
  login: {
    x: 200, y: 240, w: 260, h: 82,
    kind: 'Flow',
    short: 'Login',
    title: 'LoginCoordinator',
    subtitle: 'Email → Password',
    file: 'LoginCoordinator.swift'
  },
  tab: {
    x: 780, y: 240, w: 280, h: 82,
    kind: 'Tab',
    short: 'Main',
    title: 'MainTabCoordinator',
    subtitle: 'Home + Profile',
    file: 'MainTabCoordinator.swift'
  },
  home: {
    x: 660, y: 395, w: 220, h: 82,
    kind: 'Flow',
    short: 'Home',
    title: 'HomeCoordinator',
    subtitle: 'Planets list',
    file: 'HomeCoordinator.swift'
  },
  profile: {
    x: 920, y: 395, w: 220, h: 82,
    kind: 'Flow',
    short: 'Profile',
    title: 'ProfileCoordinator',
    subtitle: 'View / edit',
    file: 'ProfileCoordinator.swift'
  },
  detail: {
    x: 550, y: 520, w: 200, h: 64,
    kind: 'Screen',
    short: 'Detail',
    title: 'DetailView',
    subtitle: 'Planet detail',
    file: 'DetailView.swift'
  },
  settings: {
    x: 770, y: 520, w: 200, h: 64,
    kind: 'Flow',
    short: 'Settings',
    title: 'SettingsCoordinator',
    subtitle: 'Modal sheet',
    file: 'SettingsCoordinator.swift'
  }
};

// Edge styles tell the API story:
//   • `setRoot`  — atomic root swap (RootCoordinatable.setRoot(_:))
//   • `tab`      — tab membership (declared on TabCoordinatable)
//   • `push`     — route(to:) onto a flow's stack
//   • `present`  — present(_:as:) — sheet or full-screen cover
export const EDGES = [
  ['app',  'login',    { kind: 'setRoot' }],
  ['app',  'tab',      { kind: 'setRoot' }],
  ['tab',  'home',     { kind: 'tab' }],
  ['tab',  'profile',  { kind: 'tab' }],
  ['home', 'detail',   { kind: 'push' }],
  ['home', 'settings', { kind: 'present' }]
];

export const PARENT = Object.fromEntries(EDGES.map((e) => [e[1], e[0]]));

export const CODE = {
  app: `@Scaffoldable @Observable
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .unauthenticated)

    // Routes — each return type drives what kind of destination is generated.
    func unauthenticated() -> any Coordinatable { LoginCoordinator() }
    func authenticated()   -> any Coordinatable { MainTabCoordinator() }
    func about()           -> some View         { AboutView() }

    // setRoot — atomic root swap. Tears down the previous tree.
    func signIn()  { setRoot(.authenticated) }
    func signOut() { setRoot(.unauthenticated) }

    // present — RootCoordinatable can host modals directly.
    func showAbout() {
        present(.about, as: .sheet)
    }
}`,
  login: `@Scaffoldable @Observable
final class LoginCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<LoginCoordinator>(root: .email)

    func email() -> some View { EmailEntryView() }
    func password(username: String) -> some View {
        PasswordEntryView(username: username)
    }
    func forgotPassword() -> some View { ForgotPasswordView() }

    // route — push the password screen onto this flow's stack.
    func enterPassword(for username: String) {
        route(to: .password(username: username))
    }

    // present — a modal sheet on top of the current step.
    func showForgotPassword() {
        present(.forgotPassword, as: .sheet)
    }
}`,
  tab: `@Scaffoldable @Observable
final class MainTabCoordinator: @MainActor TabCoordinatable {
    var tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])

    // Each tab is a (Coordinator, Label) tuple — the macro generates
    // the destination case from the function name.
    func home() -> (any Coordinatable, some View) {
        (HomeCoordinator(), Label("Home", systemImage: "house"))
    }
    func profile() -> (any Coordinatable, some View) {
        (ProfileCoordinator(), Label("Profile", systemImage: "person"))
    }
    func notifications() -> some View { NotificationsView() }

    // selectFirstTab / appendTab / setTabs are the tab-level API.
    func openNotifications() {
        present(.notifications, as: .fullScreenCover)
    }
}`,
  home: `@Scaffoldable @Observable
final class HomeCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<HomeCoordinator>(root: .home)

    func home()             -> some View         { HomeView() }
    func detail(item: Item) -> some View         { DetailView(item: item) }
    func settings()         -> any Coordinatable { SettingsCoordinator() }

    // route — pushes onto stack.destinations.
    func openDetail(_ item: Item) {
        route(to: .detail(item: item))
    }

    // present — appends a sheet/cover destination on the same stack.
    // pop() removes whichever is on top, push or modal.
    func openSettings() {
        present(.settings, as: .sheet)
    }
}`,
  profile: `@Scaffoldable @Observable
final class ProfileCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<ProfileCoordinator>(root: .profile)

    func profile()         -> some View { ProfileView() }
    func editProfile()     -> some View { EditProfileView() }
    func signOutConfirm()  -> some View { ConfirmDialog() }

    func edit() {
        route(to: .editProfile)
    }

    func askToSignOut() {
        present(.signOutConfirm, as: .sheet)
    }
}`,
  detail: `struct DetailView: View {
    @Environment(HomeCoordinator.self) private var coordinator
    let item: Item

    var body: some View {
        VStack(spacing: 16) {
            Text(item.title).font(.title)

            // Push a deeper detail.
            Button("More") {
                coordinator.route(to: .detail(item: item.related))
            }

            // Present a modal from the parent flow.
            Button("Settings") {
                coordinator.present(.settings, as: .sheet)
            }

            // Programmatic pop — also dismisses a sheet on top.
            Button("Back") { coordinator.pop() }
        }
        .navigationTitle(item.title)
    }
}`,
  settings: `@Scaffoldable @Observable
final class SettingsCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<SettingsCoordinator>(root: .main)

    func main()          -> some View { SettingsView() }
    func notifications() -> some View { NotificationsView() }
    func privacy()       -> some View { PrivacyView() }
    func account()       -> some View { AccountView() }

    func openNotifications() {
        route(to: .notifications)
    }

    // dismissCoordinator — pops the entire SettingsCoordinator off
    // its parent. Use this when you want the whole sub-flow gone.
    func close() {
        dismissCoordinator()
    }
}`
};
