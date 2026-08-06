import SwiftUI
import Scaffolding

/// Root of the tree. A `RootCoordinatable` swaps the entire hierarchy
/// atomically — login ↔ main — with no "back" between the two states.
@MainActor
@Observable
@Scaffoldable(codable: true)
final class AppCoordinator: @MainActor RootCoordinatable {
    var root = Root<AppCoordinator>(root: .login)

    /// Snapshot persistence for the shake menu. Stored properties are never
    /// macro-tracked.
    private let snapshots = NavigationSnapshotStore()

    /// Outcome of the last save/restore, shown in the shake sheet.
    var snapshotStatus: String?

    var snapshotSavedAt: Date? { snapshots.savedAt }
    var hasSnapshot: Bool { snapshots.hasSnapshot }

    init() {
        // Default animation for every root swap; setRoot(_:animation:)
        // overrides it per call.
        setRootTransitionAnimation(.smooth(duration: 0.35))
    }

    // MARK: Routes

    func login() -> any Coordinatable { LoginCoordinator() }
    func main() -> any Coordinatable { MainTabCoordinator() }
    // View-only routes, presented modally above whatever the current root is.
    func whatsNew() -> some View { WhatsNewSheet() }
    func hierarchyDump() -> some View { HierarchyDumpSheet() }

    // MARK: Auth

    func signIn() {
        setRoot(.main)
    }

    func signOut() {
        // One-off animation override.
        setRoot(.login, animation: .easeInOut(duration: 0.25))
    }

    // MARK: Modals above the root

    /// Floats above the `TabView`/login — root-level modals suit
    /// cross-cutting UI that isn't owned by any one flow.
    func showWhatsNew() {
        present(.whatsNew, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }

    /// Debug sheet with the live coordinator tree — triggered by a device
    /// shake (⌃⌘Z in the simulator) or from the developer screen. Presented
    /// on the root so it works from any tab, flow, or the login screen.
    func showHierarchyDump() {
        present(.hierarchyDump, as: .sheet(detents: [.medium, .large]), policy: .distinct)
    }

    // MARK: Navigation snapshots

    /// Captures the whole live tree — tab selection, every flow's stack,
    /// presented modals — from this coordinator downward.
    ///
    /// The debug sheet is dismissed first so the snapshot records the app as
    /// the user sees it rather than the overlay used to trigger the save.
    /// `dismissAllModals()` mutates the model synchronously, so the capture
    /// on the next line already excludes it.
    func saveSnapshot() {
        dismissAllModals()
        do {
            snapshots.save(try captureNavigationState(), at: Date())
            snapshotStatus = "Saved"
        } catch {
            // Thrown only when this coordinator itself isn't codable.
            snapshotStatus = "Capture failed — \(error)"
        }
    }

    /// Replays the saved snapshot.
    ///
    /// The tree is rebuilt first: restoration *replays* routes (each captured
    /// push goes through `route(to:)`) rather than replacing state, so without
    /// a reset the snapshot's pushes would stack on top of wherever the user
    /// currently is. `setRoot` always resolves a fresh child, which gives the
    /// replay empty stacks to land on — and re-applying the *current* root is
    /// right either way, since the replay swaps the root itself when the
    /// snapshot was taken on the other one.
    func restoreSnapshot() {
        guard let data = snapshots.data else { return }

        dismissAllModals()
        setRoot(isRoot(.main) ? .main : .login, animation: nil)

        do {
            try restoreNavigationState(from: data)
            snapshotStatus = "Restored"
        } catch {
            // Only structurally invalid data throws; routes that no longer
            // decode are skipped so a stale snapshot degrades instead.
            snapshotStatus = "Restore failed — \(error)"
        }
    }

    func deleteSnapshot() {
        snapshots.clear()
        snapshotStatus = "Deleted"
    }

    // MARK: Deep links

    /// scaffolding-demo://holding/NVDA · scaffolding-demo://transaction/2
    func handle(_ url: URL) {
        // isRoot compares by Meta — don't deep-link past authentication.
        guard isRoot(.main) else { return }

        switch url.host() {
        case "holding":
            // Typed trailing closures: each step resolves the child and
            // hands it over. Note setRoot re-runs the route function — the
            // main tree is rebuilt, which is the cold-launch pattern.
            // selectFirstTab here is programmatic, so shouldSelect (the
            // invest disclaimer guard) is bypassed.
            let symbol = url.lastPathComponent
            setRoot(.main) { (tab: MainTabCoordinator) in
                tab.selectFirstTab(.invest) { (invest: InvestCoordinator) in
                    invest.showHolding(symbol: symbol)
                }
            }
        case "transaction":
            // The same walk with the expecting: variants — flatter, and easy
            // to branch mid-chain.
            guard let id = Int(url.lastPathComponent) else { return }
            let tab = setRoot(.main, expecting: MainTabCoordinator.self)
            let home = tab?.selectFirstTab(.home, expecting: HomeCoordinator.self)
            home?.showTransaction(id: id)
        default:
            break
        }
    }

    // Returns `some View`, so the macro would track it — chrome, not a route.
    @ScaffoldingIgnored
    func customize(_ view: AnyView) -> some View {
        view.tint(.white)
    }
}
