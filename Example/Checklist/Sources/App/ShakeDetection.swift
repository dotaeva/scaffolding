import SwiftUI
import Combine

/// Cross-platform shim: runs `action` on device shake on iOS, no-op on
/// macOS (which opens the same sheet from the Debug menu).
extension View {
    @ViewBuilder
    func onShake(_ action: @escaping () -> Void) -> some View {
        #if os(iOS)
        onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
            action()
        }
        #else
        self
        #endif
    }
}

#if os(iOS)
import UIKit

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .deviceDidShake, object: nil)
        }
        super.motionEnded(motion, with: event)
    }
}
#endif
