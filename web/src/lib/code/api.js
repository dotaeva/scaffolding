// Per-symbol code snippets for /docs/api.

export const CODE_COORDINATABLE = `@MainActor
public protocol Coordinatable: AnyObject, Identifiable {
    associatedtype Destinations: Destinationable
        where Destinations.Owner == Self
    associatedtype ViewType: View

    var parent: (any Coordinatable)? { get }
    var view: ViewType { get }
    func customize(_ view: AnyView) -> CustomizeContentView
}`;

export const CODE_FLOW_PROTOCOL = `@MainActor
public protocol FlowCoordinatable: Coordinatable
    where ViewType == FlowCoordinatableView {

    var stack: FlowStack<Self> { get }
}`;

export const CODE_TAB_PROTOCOL = `@MainActor
public protocol TabCoordinatable: Coordinatable
    where ViewType == TabCoordinatableView {

    var tabItems: TabItems<Self> { get }
}`;

export const CODE_ROOT_PROTOCOL = `@MainActor
public protocol RootCoordinatable: Coordinatable
    where ViewType == RootCoordinatableView {

    var root: Root<Self> { get }
}`;

export const CODE_FLOWSTACK = `@MainActor @Observable
public final class FlowStack<Coordinator: FlowCoordinatable> {
    public var root: Destination?
    public var destinations: [Destination] = []   // pushes + modals
    public var animation: Animation? = .default
    public var presentedAs: PresentationType?
    public weak var parent: (any Coordinatable)?
}`;

export const CODE_ROOTC = `@MainActor @Observable
public final class Root<Coordinator: RootCoordinatable> {
    public var root: Destination?
    public var animation: Animation? = .default
    public var presentedAs: PresentationType?
    public var modals: [Destination] = []
}`;

export const CODE_TABITEMS = `@MainActor @Observable
public final class TabItems<Coordinator: TabCoordinatable> {
    public var tabs: [Destination] = []
    public var selectedTab: UUID? = nil
    public var tabBarVisibility: Visibility = .automatic
    public var modals: [Destination] = []
}`;

export const CODE_DESTINATION = `public struct Destination: Identifiable, Hashable {
    public var id: UUID
    public var routeType: DestinationType
    public var presentationType: DestinationType
    public let meta: any DestinationMeta
}`;

export const CODE_DEST_TYPES = `public enum DestinationType {
    case root, push, sheet, fullScreenCover
}

public enum PresentationType {
    case push, sheet, fullScreenCover
}

public enum ModalPresentationType {
    case sheet, fullScreenCover
}`;

export const CODE_DESTINATIONABLE = `@MainActor
public protocol Destinationable {
    associatedtype Meta: DestinationMeta
    associatedtype Owner

    var meta: Meta { get }
    func value(for instance: Owner) -> Destination
}

@MainActor
public protocol DestinationMeta: Equatable { }`;

export const CODE_SCAFFOLDABLE = `@attached(member, names: named(Destinations), named(_injectsCoordinator))
public macro Scaffoldable(injectsCoordinator: Bool = true)
    = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldableMacro")`;

export const CODE_SCAFFOLDING_TRACKED = `@attached(peer)
public macro ScaffoldingTracked()
    = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingTrackedMacro")`;

export const CODE_SCAFFOLDING_IGNORED = `@attached(peer)
public macro ScaffoldingIgnored()
    = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingIgnoredMacro")`;
