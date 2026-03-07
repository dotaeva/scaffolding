/// Generates a `Destinations` enum for a coordinator class.
///
/// Apply `@Scaffoldable` to an `@Observable` class that conforms to
/// ``FlowCoordinatable``, ``TabCoordinatable``, or ``RootCoordinatable``.
/// The macro inspects every function whose return type is `some View`,
/// `any Coordinatable`, or a supported tuple and synthesises a
/// `Destinations` enum with one case per function.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class HomeCoordinator: @MainActor FlowCoordinatable {
///     var stack = FlowStack<HomeCoordinator>(root: .home)
///
///     func home() -> some View { HomeView() }
///     func detail(item: String) -> some View { DetailView(item: item) }
/// }
/// ```
@attached(member, names: named(Destinations))
public macro Scaffoldable() = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldableMacro")

/// Explicitly marks a function for inclusion in the generated `Destinations` enum.
///
/// By default ``Scaffoldable()`` includes every eligible function. Use
/// `@ScaffoldingTracked` when you want to be explicit about which functions
/// participate in code generation — functions without the attribute are then
/// excluded.
@attached(peer)
public macro ScaffoldingTracked() = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingTrackedMacro")

/// Excludes a function from the generated `Destinations` enum.
///
/// Apply `@ScaffoldingIgnored` to any function on a ``Scaffoldable()``
/// coordinator that should **not** become a destination case.
///
/// ```swift
/// @ScaffoldingIgnored
/// func helperView() -> some View { Text("Not a destination") }
/// ```
@attached(peer)
public macro ScaffoldingIgnored() = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingIgnoredMacro")
