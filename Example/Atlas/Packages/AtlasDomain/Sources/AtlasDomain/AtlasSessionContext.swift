import Foundation
import Observation

public enum AtlasMessageAction {
    case journey(UUID)
    case undoRemoval(TripPlan)

    public var title: String {
        switch self { case .journey: "View journey"; case .undoRemoval: "Undo" }
    }
}

public struct AtlasMessage: Identifiable {
    public let id = UUID()
    public let text: String
    public let action: AtlasMessageAction?
}

/// Feedback and app capabilities are scoped to a window, separately from saved content.
@MainActor @Observable
public final class AtlasSessionContext {
    public weak var actions: (any AtlasSessionActions)?
    public private(set) var message: AtlasMessage?
    public let store: AtlasStore

    public init(store: AtlasStore) { self.store = store }
    public func show(_ text: String, action: AtlasMessageAction? = nil) {
        message = AtlasMessage(text: text, action: action)
    }
    public func dismissMessage() { message = nil }
    public func performMessageAction() {
        let action = message?.action
        message = nil
        switch action {
        case .journey(let id): actions?.openJourney(id)
        case .undoRemoval(let plan): store.add(plan)
        case nil: break
        }
    }
}
