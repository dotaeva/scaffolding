import SwiftUI

extension Animation {
    /// Spring, not a timing curve: scroll direction flips mid-animation
    /// constantly, and a spring retargets while preserving velocity.
    /// Critically damped (bounce 0): no overshoot and no settling tail,
    /// which matters because the bar animates layout.
    static let tabBarMinimize = Animation.spring(duration: 0.38, bounce: 0)
    /// Slide spring: interruptible by design — rapid tab-hopping retargets
    /// with preserved velocity. Slight under-damping gives the pill a tiny
    /// settle, safe here because it's transform-only.
    static let tabSlide = Animation.spring(duration: 0.42, bounce: 0.18)
}
