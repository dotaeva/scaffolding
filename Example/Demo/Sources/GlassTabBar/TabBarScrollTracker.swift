import SwiftUI
import UIKit

extension View {
    /// Installs app-wide scroll tracking that drives the glass bar's
    /// minimize behaviour. Apply **once**, on the tab chrome.
    ///
    /// SwiftUI has no modifier that can do this from one place. Attached
    /// above a `NavigationStack`, `onScrollGeometryChange` binds to the root
    /// screen's scroll view and nothing else — measured: scrolling a tab root
    /// reports, scrolling a pushed screen in the same flow reports nothing.
    /// Attaching it per screen works but every new screen has to remember it.
    ///
    /// A single pan recognizer on the window sees scrolling anywhere instead:
    /// tab roots, pushed screens, and any screen added later.
    func tracksScrollForTabBar(_ model: GlassTabBarModel) -> some View {
        background(TabBarScrollTracker(model: model).frame(width: 0, height: 0))
    }
}

private struct TabBarScrollTracker: UIViewRepresentable {
    let model: GlassTabBarModel

    func makeUIView(context: Context) -> UIView { TrackerView(model: model) }
    func updateUIView(_ uiView: UIView, context: Context) { }
}

private final class TrackerView: UIView, UIGestureRecognizerDelegate {
    private let model: GlassTabBarModel
    private var installed: UIPanGestureRecognizer?
    private var lastY: CGFloat = 0

    init(model: GlassTabBarModel) {
        self.model = model
        super.init(frame: .zero)
        isUserInteractionEnabled = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard installed == nil, let window else { return }

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan.delegate = self
        // Observe only — the scroll views below must keep every touch.
        pan.cancelsTouchesInView = false
        pan.delaysTouchesBegan = false
        pan.delaysTouchesEnded = false
        window.addGestureRecognizer(pan)
        installed = pan
    }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        guard let window else { return }
        // While the bar is being scrubbed the finger owns it; don't fight.
        guard !model.isDragging else { return }

        switch pan.state {
        case .began:
            lastY = pan.translation(in: window).y
        case .changed:
            let y = pan.translation(in: window).y
            let dy = y - lastY
            guard abs(dy) > 3 else { return }
            lastY = y

            // Near the top of whatever is being scrolled, always expand —
            // same rule the scroll-geometry version used.
            if let scrollView = scrollView(under: pan.location(in: window), in: window),
               scrollView.contentOffset.y + scrollView.adjustedContentInset.top < 24 {
                model.setMinimized(false)
                return
            }
            // Dragging up means scrolling down into the content.
            model.setMinimized(dy < 0)
        default:
            break
        }
    }

    private func scrollView(under point: CGPoint, in window: UIWindow) -> UIScrollView? {
        var node = window.hitTest(point, with: nil)
        while let current = node {
            if let scrollView = current as? UIScrollView { return scrollView }
            node = current.superview
        }
        return nil
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer
    ) -> Bool {
        true
    }
}
