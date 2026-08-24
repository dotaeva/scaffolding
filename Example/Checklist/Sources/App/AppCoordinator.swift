import SwiftUI
import Scaffolding

/// Root of the tree. A `RootCoordinatable` swaps the whole hierarchy
/// atomically — onboarding ↔ main — with no "back" between the two.
///
/// It is also the app's composition root: it owns the store and builds the
/// shell that suits the device.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .onboarding)

    /// Domain state. Stored properties are never macro-tracked.
    let store: TodoStore

    /// Tabs on iPhone, three columns on iPad/Mac.
    let layout: MainLayout

    init(store: TodoStore = TodoStore(), layout: MainLayout = .current) {
        self.store = store
        self.layout = layout
        // Default animation for every root swap; setRoot(_:animation:)
        // overrides it per call.
        setRootTransitionAnimation(.smooth(duration: 0.3))
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func onboarding() -> any Coordinatable {
        // Result delivery: the presenter installs the completion at
        // construction time; the child never reaches back up the tree.
        OnboardingCoordinator(store: store) { [weak self] in
            self?.finishOnboarding()
        }
    }

    func main() -> any Coordinatable {
        layout == .split
            ? MainSplitCoordinator(store: store)
            : MainTabCoordinator(store: store)
    }

    /// View-only route, presented above whatever the current root is.
    func hierarchy() -> some View { HierarchySheet() }
}

// MARK: - Root swaps

extension AppCoordinator {
    func finishOnboarding() {
        setRoot(.main)
    }

    /// Settings → "Restart Onboarding", reached with `ancestor(ofType:)`
    /// from a coordinator deep in the tree.
    func restartOnboarding() {
        setRoot(.onboarding, animation: .easeInOut(duration: 0.25))
    }
}

// MARK: - Root modal

extension AppCoordinator {
    /// The coordinator-tree inspector: device shake on iOS (⌃⌘Z in the
    /// simulator), ⇧⌘D on macOS. Presented on the root, so it works from
    /// any tab, column, or flow.
    func showHierarchy() {
        present(.hierarchy, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }
}

// MARK: - Menu commands (macOS)

extension AppCoordinator {
    /// ⌘N has no view context to route from, so it looks the live shell up
    /// in the public hierarchy snapshot — which never materialises
    /// anything — instead of the app holding a child reference.
    func newTodoCommand() {
        shell(MainSplitCoordinator.self)?.addTodo()
        shell(MainTabCoordinator.self)?.addTodo()
    }

    private func shell<T: Coordinatable>(_ type: T.Type) -> T? {
        hierarchySnapshot().compactMap { $0.coordinator as? T }.first
    }
}

// MARK: - Chrome

extension AppCoordinator {
    // In an extension the macro never sees this — no @ScaffoldingIgnored
    // needed, unlike a `some View` helper in the class body.
    func customize(_ view: AnyView) -> some View {
        view.tint(.blue)
    }
}
