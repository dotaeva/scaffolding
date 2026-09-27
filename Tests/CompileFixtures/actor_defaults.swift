import SwiftUI
import Scaffolding

@MainActor @Observable @Scaffoldable(codable: true)
public final class PublicDefaultsCoordinator: FlowCoordinatable {
    private static var defaultID = 42
    public var stack = FlowStack<PublicDefaultsCoordinator>(root: .detail())
    public init() {}
    func detail(id: Int = defaultID, title: String = "Detail") -> some View { Text(title) }
    func source(line: Int = #line, file: String = #fileID) -> some View { EmptyView() }
    func positional(_ id: Int = defaultID, _ other: Int = 8) -> some View { EmptyView() }
    @available(macOS 99, iOS 99, tvOS 99, watchOS 99, *)
    func future(id: Int = defaultID) -> some View { EmptyView() }
}

@MainActor func checkDefaults() {
    let owner = PublicDefaultsCoordinator()
    owner.route(to: .source())
    owner.route(to: .detail())
    owner.route(to: .detail(id: 1))
    owner.route(to: .detail(title: "Other"))
    owner.route(to: .detail(id: 1, title: "Other"))
    owner.route(to: .positional())
    owner.route(to: .positional(9))
    owner.route(to: .positional(9, 8))
    if #available(macOS 99, iOS 99, tvOS 99, watchOS 99, *) {
        owner.route(to: .future())
    }
}
