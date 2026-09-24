import SwiftUI
import Toasts

/// Drains a ``ToastCenter`` into swiftui-toasts' `presentToast` action.
///
/// This is the only place in the app that needs to be both "inside the
/// view tree" (so it can read the environment) and "outside any screen"
/// (so it survives pushes, sheets, and root swaps). Mounted once, next to
/// `installToast()`.
///
/// The library owns display and timing from here on; ``ToastCenter``
/// remains the source of truth for *what* was posted, which is what the
/// tests assert against. It draws in its own window, above sheets and
/// covers — the one surface still reachable while a modal is up.
private struct ToastBridge: View {
    let center: ToastCenter

    /// Items already handed to the library. Without it, any re-evaluation
    /// would present the whole queue again.
    @State private var forwarded: Set<ToastCenter.Item.ID> = []

    @Environment(\.presentToast) private var presentToast

    var body: some View {
        // Reading the ids here is what registers the Observation
        // dependency — without touching the queue in `body`, onChange
        // never fires.
        Color.clear
            .onChange(of: center.queue.map(\.id), initial: true) { _, ids in
                forwarded.formIntersection(Set(ids))
                for item in center.queue where !forwarded.contains(item.id) {
                    forwarded.insert(item.id)
                    present(item)
                }
            }
    }

    private func present(_ item: ToastCenter.Item) {
        presentToast(
            ToastValue(
                icon: Image(systemName: item.symbol).foregroundStyle(item.tint),
                message: item.message,
                button: item.action.map { action in
                    ToastButton(title: action.title, color: .accentColor) {
                        action.perform()
                    }
                },
                // Long enough to actually reach an action.
                duration: item.action == nil ? 3 : 8
            )
        )
    }
}

extension View {
    /// Mount once, at the app root.
    func toastPresentation(_ center: ToastCenter) -> some View {
        background(ToastBridge(center: center))
            .installToast(position: .top)
    }
}
