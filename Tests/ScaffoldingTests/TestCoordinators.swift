//
//  TestCoordinators.swift
//  ScaffoldingTests
//
//  Manually-written coordinator hierarchy for testing parent chains,
//  setup behavior, and navigation without relying on the @Scaffoldable macro.
//

import SwiftUI
import Observation
@testable import Scaffolding

// MARK: - Helpers

/// Walks the parent chain from a coordinatable and collects all ancestors.
@MainActor
func collectAncestors(from coordinatable: any Coordinatable) -> [any Coordinatable] {
    var result: [any Coordinatable] = []
    var current = coordinatable.parent
    while let c = current {
        result.append(c)
        current = c.parent
    }
    return result
}

/// Checks if a specific coordinator is reachable via the parent chain.
@MainActor
func canFindAncestor<T: Coordinatable>(ofType _: T.Type, from coordinatable: any Coordinatable) -> Bool {
    var current = coordinatable.parent
    while let c = current {
        if c is T { return true }
        current = c.parent
    }
    return false
}

/// Returns a specific ancestor by type, or nil.
@MainActor
func findAncestor<T: Coordinatable>(ofType _: T.Type, from coordinatable: any Coordinatable) -> T? {
    var current = coordinatable.parent
    while let c = current {
        if let match = c as? T { return match }
        current = c.parent
    }
    return nil
}

// MARK: - LeafFlowCoordinator

@MainActor @Observable
final class LeafFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<LeafFlowCoordinator>

    init() {
        self.stack = FlowStack<LeafFlowCoordinator>(root: .leaf)
    }

    func leaf() -> some View { EmptyView() }

    enum Destinations: Destinationable {
        typealias Owner = LeafFlowCoordinator
        case leaf

        enum Meta: DestinationMeta {
            case leaf
        }

        var meta: Meta {
            switch self {
            case .leaf: return .leaf
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .leaf:
                return Destination(instance.leaf(), meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - DetailFlowCoordinator

@MainActor @Observable
final class DetailFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<DetailFlowCoordinator>

    init() {
        self.stack = FlowStack<DetailFlowCoordinator>(root: .detail)
    }

    func detail() -> some View { EmptyView() }
    func subDetail() -> any Coordinatable { LeafFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = DetailFlowCoordinator
        case detail
        case subDetail

        enum Meta: DestinationMeta {
            case detail
            case subDetail
        }

        var meta: Meta {
            switch self {
            case .detail: return .detail
            case .subDetail: return .subDetail
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .detail:
                return Destination(instance.detail(), meta: meta, parent: instance)
            case .subDetail:
                return Destination({ instance.subDetail() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - HomeFlowCoordinator

@MainActor @Observable
final class HomeFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<HomeFlowCoordinator>

    init() {
        self.stack = FlowStack<HomeFlowCoordinator>(root: .home)
    }

    func home() -> some View { EmptyView() }
    func detail() -> any Coordinatable { DetailFlowCoordinator() }
    func settings() -> some View { EmptyView() }
    func sheetFlow() -> any Coordinatable { LeafFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = HomeFlowCoordinator
        case home
        case detail
        case settings
        case sheetFlow

        enum Meta: DestinationMeta {
            case home
            case detail
            case settings
            case sheetFlow
        }

        var meta: Meta {
            switch self {
            case .home: return .home
            case .detail: return .detail
            case .settings: return .settings
            case .sheetFlow: return .sheetFlow
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .home:
                return Destination(instance.home(), meta: meta, parent: instance)
            case .detail:
                return Destination({ instance.detail() }, meta: meta, parent: instance)
            case .settings:
                return Destination(instance.settings(), meta: meta, parent: instance)
            case .sheetFlow:
                return Destination({ instance.sheetFlow() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - ProfileFlowCoordinator

@MainActor @Observable
final class ProfileFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<ProfileFlowCoordinator>

    init() {
        self.stack = FlowStack<ProfileFlowCoordinator>(root: .profile)
    }

    func profile() -> some View { EmptyView() }

    enum Destinations: Destinationable {
        typealias Owner = ProfileFlowCoordinator
        case profile

        enum Meta: DestinationMeta {
            case profile
        }

        var meta: Meta {
            switch self {
            case .profile: return .profile
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .profile:
                return Destination(instance.profile(), meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - SettingsFlowCoordinator

@MainActor @Observable
final class SettingsFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<SettingsFlowCoordinator>

    init() {
        self.stack = FlowStack<SettingsFlowCoordinator>(root: .main)
    }

    func main() -> some View { EmptyView() }

    enum Destinations: Destinationable {
        typealias Owner = SettingsFlowCoordinator
        case main

        enum Meta: DestinationMeta {
            case main
        }

        var meta: Meta {
            switch self {
            case .main: return .main
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .main:
                return Destination(instance.main(), meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - MainTabCoordinator

@MainActor @Observable
final class MainTabCoordinator: TabCoordinatable {
    var tabItems: TabItems<MainTabCoordinator>

    init() {
        self.tabItems = TabItems<MainTabCoordinator>(tabs: [.home, .profile])
    }

    func home() -> any Coordinatable { HomeFlowCoordinator() }
    func profile() -> any Coordinatable { ProfileFlowCoordinator() }
    func settings() -> any Coordinatable { SettingsFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = MainTabCoordinator
        case home
        case profile
        case settings

        enum Meta: DestinationMeta {
            case home
            case profile
            case settings
        }

        var meta: Meta {
            switch self {
            case .home: return .home
            case .profile: return .profile
            case .settings: return .settings
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .home:
                return Destination({ instance.home() }, meta: meta, parent: instance)
            case .profile:
                return Destination({ instance.profile() }, meta: meta, parent: instance)
            case .settings:
                return Destination({ instance.settings() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - LoginFlowCoordinator

@MainActor @Observable
final class LoginFlowCoordinator: FlowCoordinatable {
    var stack: FlowStack<LoginFlowCoordinator>

    init() {
        self.stack = FlowStack<LoginFlowCoordinator>(root: .login)
    }

    func login() -> some View { EmptyView() }

    enum Destinations: Destinationable {
        typealias Owner = LoginFlowCoordinator
        case login

        enum Meta: DestinationMeta {
            case login
        }

        var meta: Meta {
            switch self {
            case .login: return .login
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .login:
                return Destination(instance.login(), meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - AppRootCoordinator

@MainActor @Observable
final class AppRootCoordinator: RootCoordinatable {
    var root: Root<AppRootCoordinator>

    init() {
        self.root = Root<AppRootCoordinator>(root: .main)
    }

    func main() -> any Coordinatable { MainTabCoordinator() }
    func login() -> any Coordinatable { LoginFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = AppRootCoordinator
        case main
        case login

        enum Meta: DestinationMeta {
            case main
            case login
        }

        var meta: Meta {
            switch self {
            case .main: return .main
            case .login: return .login
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .main:
                return Destination({ instance.main() }, meta: meta, parent: instance)
            case .login:
                return Destination({ instance.login() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - NestedRootCoordinator (Root inside Root)

@MainActor @Observable
final class InnerRootCoordinator: RootCoordinatable {
    var root: Root<InnerRootCoordinator>

    init() {
        self.root = Root<InnerRootCoordinator>(root: .content)
    }

    func content() -> any Coordinatable { HomeFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = InnerRootCoordinator
        case content

        enum Meta: DestinationMeta {
            case content
        }

        var meta: Meta {
            switch self {
            case .content: return .content
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .content:
                return Destination({ instance.content() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - OuterRootCoordinator (Root wrapping another Root)

@MainActor @Observable
final class OuterRootCoordinator: RootCoordinatable {
    var root: Root<OuterRootCoordinator>

    init() {
        self.root = Root<OuterRootCoordinator>(root: .inner)
    }

    func inner() -> any Coordinatable { InnerRootCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = OuterRootCoordinator
        case inner

        enum Meta: DestinationMeta {
            case inner
        }

        var meta: Meta {
            switch self {
            case .inner: return .inner
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .inner:
                return Destination({ instance.inner() }, meta: meta, parent: instance)
            }
        }
    }
}

// MARK: - FlowWithCoordinatorRoot (FlowStack whose root is a coordinator, not a view)

@MainActor @Observable
final class FlowWithCoordinatorRootCoordinator: FlowCoordinatable {
    var stack: FlowStack<FlowWithCoordinatorRootCoordinator>

    init() {
        self.stack = FlowStack<FlowWithCoordinatorRootCoordinator>(root: .child)
    }

    func child() -> any Coordinatable { DetailFlowCoordinator() }
    func other() -> any Coordinatable { LeafFlowCoordinator() }

    enum Destinations: Destinationable {
        typealias Owner = FlowWithCoordinatorRootCoordinator
        case child
        case other

        enum Meta: DestinationMeta {
            case child
            case other
        }

        var meta: Meta {
            switch self {
            case .child: return .child
            case .other: return .other
            }
        }

        func value(for instance: Owner) -> Destination {
            switch self {
            case .child:
                return Destination({ instance.child() }, meta: meta, parent: instance)
            case .other:
                return Destination({ instance.other() }, meta: meta, parent: instance)
            }
        }
    }
}
