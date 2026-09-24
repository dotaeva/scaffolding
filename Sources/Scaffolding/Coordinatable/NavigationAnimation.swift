import SwiftUI

/// An animation policy for a synchronous scope of navigation changes.
///
/// Pass it to ``withNavigationTransaction(animation:_:)``.
public enum NavigationAnimation {
    /// Use each coordinator's default animation.
    case automatic
    /// Disable navigation animation and implicit SwiftUI animations.
    case disabled
    /// Use this animation for every coordinator the scope changes.
    case custom(Animation)
}

/// Applies an animation policy to every navigation change in `changes`.
///
/// ```swift
/// withNavigationTransaction(animation: .disabled) {
///     let tabs = app.setRoot(.main, expecting: MainTabCoordinator.self)
///     let home = tabs?.selectFirstTab(.home, expecting: HomeCoordinator.self)
///     home?.route(to: .detail(id: 42))
/// }
/// ```
///
/// Scopes nest and restore the enclosing policy on return or throw. The
/// policy doesn't carry into tasks started inside `changes`.
///
/// - Parameters:
///   - animation: The policy for the scope.
///   - changes: Synchronous navigation calls.
/// - Returns: The value `changes` returns.
@MainActor
@discardableResult
public func withNavigationTransaction<Value>(
    animation: NavigationAnimation,
    _ changes: () throws -> Value
) rethrows -> Value {
    let previous = NavigationAnimationContext.policy
    NavigationAnimationContext.policy = animation
    defer { NavigationAnimationContext.policy = previous }
    return try withScaffoldingAnimation(nil, changes)
}

@MainActor
enum NavigationAnimationContext {
    static var policy: NavigationAnimation = .automatic

    static func transaction(default animation: Animation?) -> Transaction {
        switch policy {
        case .automatic:
            return Transaction(animation: animation)
        case .custom(let animation):
            return Transaction(animation: animation)
        case .disabled:
            var transaction = Transaction(animation: nil)
            transaction.disablesAnimations = true
            return transaction
        }
    }
}

@MainActor
@discardableResult
func withScaffoldingAnimation<Value>(_ animation: Animation?, _ body: () throws -> Value) rethrows -> Value {
    try withTransaction(NavigationAnimationContext.transaction(default: animation), body)
}
