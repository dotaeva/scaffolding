/// Generates a `Destinations` enum for a coordinator class.
///
/// Apply `@Scaffoldable` to an `@Observable` class that conforms to
/// ``FlowCoordinatable``, ``TabCoordinatable``, or ``RootCoordinatable``.
/// The macro inspects every function whose return type is `some View`,
/// `any Coordinatable`, or a supported tab tuple and synthesises a
/// `Destinations` enum with one case per function.
///
/// ```swift
/// @Scaffoldable @Observable
/// final class AppCoordinator: @MainActor FlowCoordinatable {
///     var stack = FlowStack<AppCoordinator>(root: .home)
///
///     func home() -> some View { HomeView() }
///     func detail(id: String) -> some View { DetailView(id: id) }
///     func login(onComplete: @escaping (AuthToken) -> Void) -> any Coordinatable {
///         LoginCoordinator(onComplete: onComplete)
///     }
/// }
///
/// // Use:
/// coord.route(to: .detail(id: "x"))                       // push
/// coord.present(.login(onComplete: { … }), as: .sheet)    // sheet
/// ```
///
/// Pass `injectsCoordinator: false` to opt this coordinator out of
/// automatic environment injection — useful when a screen should not see
/// the coordinator that owns it (for example, a reusable view that
/// shouldn't bind to a specific flow).
@attached(member, names: named(Destinations), named(_injectsCoordinator))
public macro Scaffoldable(injectsCoordinator: Bool = true) = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldableMacro")

/// Excludes a function from the generated `Destinations` enum.
///
/// Apply `@ScaffoldingIgnored` to any function on a ``Scaffoldable(injectsCoordinator:)``
/// coordinator that should **not** become a destination case.
///
/// ```swift
/// @ScaffoldingIgnored
/// func helperView() -> some View { Text("Not a destination") }
/// ```
@attached(peer)
public macro ScaffoldingIgnored() = #externalMacro(module: "ScaffoldingMacros", type: "ScaffoldingIgnoredMacro")
