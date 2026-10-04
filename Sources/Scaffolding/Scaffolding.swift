/// Generates the `Destinations` enum for a coordinator class.
///
/// Attach it to a class conforming to ``FlowCoordinatable``,
/// ``TabCoordinatable``, ``RootCoordinatable``, or ``SplitCoordinatable``.
/// Each class-body function returning `some View`, `any Coordinatable`, or a
/// tab tuple becomes a case, and its parameters become associated values.
/// Functions in extensions are never scanned.
///
/// ```swift
/// @MainActor @Observable @Scaffoldable
/// final class HomeCoordinator: @MainActor FlowCoordinatable {
///     var stack = FlowStack<HomeCoordinator>(root: .home)
///
///     func home() -> some View { HomeView() }
///     func detail(id: Int) -> some View { DetailView(id: id) }
///     func settings() -> any Coordinatable { SettingsCoordinator() }
/// }
///
/// coordinator.route(to: .detail(id: 42))
/// ```
///
/// `injectsCoordinator` (default `true`) injects the coordinator into its
/// views' environment. Pass `false` to hide this coordinator; its ancestors
/// stay visible.
///
/// `codable` (default `false`) makes `Destinations` `Codable` for
/// <doc:StateRestoration>. Every route parameter must then be `Codable`.
///
/// Both options take a literal `true` or `false`. See <doc:DefiningRoutes>.
@attached(member, names: named(Destinations), named(_injectsCoordinator), named(__ScaffoldingRouteTypes))
public macro Scaffoldable(injectsCoordinator: Bool = true, codable: Bool = false) = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldableMacro")

/// Keeps a class-body function out of the generated `Destinations` enum.
///
/// Use it only on a function whose return type would otherwise make it a
/// route, such as `customize(_:)` or a shared view builder. Properties,
/// `Void` helpers, and functions in extensions need no annotation.
///
/// ```swift
/// @ScaffoldingIgnored
/// func emptyState(message: String) -> some View { Text(message) }
/// ```
@attached(peer)
public macro ScaffoldingIgnored() = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingIgnoredMacro")
