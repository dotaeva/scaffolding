import SwiftUI
import Observation

/// The queue of navigation outcomes currently on screen as toasts.
///
/// Coordinators are the right place to *decide* that "the sheet returned
/// 3" or "the pushed screen was popped" — but a coordinator is not a
/// `View`, so it cannot present anything itself. It appends here, and
/// ``ToastBridge`` hands whatever is in the queue to swiftui-toasts.
///
/// The indirection outlives the screen that triggered it: a root swap
/// tears down the view that started the work, and a toast owned by that
/// view would die with it. This queue lives on the app root, so
/// "Signed in as …" still lands after the whole hierarchy is replaced.
@MainActor
@Observable
final class ToastCenter {
    struct Item: Identifiable, Equatable {
        let id = UUID()
        let message: String
        let symbol: String
        let tint: Color
        /// An action offered on the toast itself — an undo, or a dismissal
        /// for something that covered its own trigger.
        var action: (title: String, perform: () -> Void)?

        static func ==(lhs: Item, rhs: Item) -> Bool { lhs.id == rhs.id }
    }

    /// Newest last. ``ToastBridge`` hands these to swiftui-toasts;
    /// nothing else should mutate it.
    private(set) var queue: [Item] = []

    /// How many toasts stay on screen at once before the oldest is dropped.
    private let limit = 3

    func show(_ message: String, symbol: String = "checkmark.circle.fill", tint: Color = .green) {
        enqueue(Item(message: message, symbol: symbol, tint: tint), seconds: 3)
    }

    /// A toast that can act on what it is reporting — an undo for a root
    /// swap, or the dismissal of a modal that covered the button for it.
    /// Given longer on screen, because it has to be reachable.
    func show(
        _ message: String,
        symbol: String = "info.circle.fill",
        tint: Color = .secondary,
        actionTitle: String,
        perform: @escaping () -> Void
    ) {
        enqueue(
            Item(message: message, symbol: symbol, tint: tint,
                 action: (title: actionTitle, perform: perform)),
            seconds: 8
        )
    }

    /// A navigation call that was skipped, cancelled, or returned nothing.
    func showNeutral(_ message: String, symbol: String = "xmark.circle.fill") {
        show(message, symbol: symbol, tint: .secondary)
    }

    func showWarning(_ message: String, symbol: String = "exclamationmark.triangle.fill") {
        show(message, symbol: symbol, tint: .orange)
    }

    func dismiss(_ id: Item.ID) {
        queue.removeAll { $0.id == id }
    }

    private func enqueue(_ item: Item, seconds: Double) {
        queue.append(item)
        if queue.count > limit { queue.removeFirst() }

        Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            self?.dismiss(item.id)
        }
    }
}
