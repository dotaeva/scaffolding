//
//  TabBarAccessibilityIdentifierBridge.swift
//  Scaffolding
//
//  Applies tab accessibility identifiers to UIKit tab bar controls.
//

import SwiftUI

#if os(iOS) && canImport(UIKit)
import UIKit

@available(iOS 18, macOS 15, *)
@MainActor
private struct TabBarAccessibilityIdentifierBridge: UIViewControllerRepresentable {
    let metadata: [TabBarAccessibilityIdentifier]

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.isHidden = true
        context.coordinator.hostController = controller
        context.coordinator.scheduleApply(metadata)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.hostController = uiViewController
        context.coordinator.scheduleApply(metadata)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    @MainActor
    final class Coordinator {
        weak var hostController: UIViewController?
        private var applyTask: Task<Void, Never>?
        private var previouslyManagedIdentifiers: Set<String> = []

        deinit {
            applyTask?.cancel()
        }

        func scheduleApply(_ metadata: [TabBarAccessibilityIdentifier]) {
            applyTask?.cancel()

            applyTask = Task { @MainActor [weak hostController = hostController] in
                for attempt in 0..<10 {
                    guard !Task.isCancelled else { return }
                    let didApply = apply(metadata, from: hostController)
                    if didApply || attempt == 9 { return }

                    try? await Task.sleep(nanoseconds: 50_000_000)
                }
            }
        }

        private func apply(
            _ metadata: [TabBarAccessibilityIdentifier],
            from hostController: UIViewController?
        ) -> Bool {
            guard let tabBarController = hostController?.nearestTabBarController()
                ?? hostController?.view.window?.rootViewController?.firstTabBarController() else {
                return false
            }

            let controls = tabBarController.tabBar.descendantControls()
            guard !controls.isEmpty else { return false }

            for control in controls where previouslyManagedIdentifiers.contains(control.accessibilityIdentifier ?? "") {
                control.accessibilityIdentifier = nil
            }

            previouslyManagedIdentifiers = Set(metadata.map(\.identifier))

            let matchableMetadata = metadata.filter { !$0.matchingLabels.isEmpty }
            guard !matchableMetadata.isEmpty else { return true }

            for control in controls {
                guard let label = control.accessibilityLabel ?? control.firstDescendantLabelText(),
                      let match = matchableMetadata.first(where: { $0.matches(renderedLabel: label) }) else { continue }

                control.accessibilityIdentifier = match.identifier
            }

            return true
        }
    }
}

@available(iOS 18, macOS 15, *)
private extension UIViewController {
    func nearestTabBarController() -> UITabBarController? {
        var current: UIViewController? = self
        while let controller = current {
            if let tabBarController = controller as? UITabBarController {
                return tabBarController
            }
            current = controller.parent
        }

        return nil
    }

    func firstTabBarController() -> UITabBarController? {
        if let tabBarController = self as? UITabBarController {
            return tabBarController
        }

        for child in children {
            if let tabBarController = child.firstTabBarController() {
                return tabBarController
            }
        }

        if let presentedViewController,
           let tabBarController = presentedViewController.firstTabBarController() {
            return tabBarController
        }

        return nil
    }
}

@available(iOS 18, macOS 15, *)
private extension UIView {
    func descendantControls() -> [UIControl] {
        var controls: [UIControl] = []

        for subview in subviews {
            if let control = subview as? UIControl {
                controls.append(control)
            } else {
                controls.append(contentsOf: subview.descendantControls())
            }
        }

        return controls
    }

    func firstDescendantLabelText() -> String? {
        for subview in subviews {
            if let label = subview as? UILabel,
               let text = label.text,
               !text.isEmpty {
                return text
            }

            if let text = subview.firstDescendantLabelText() {
                return text
            }
        }

        return nil
    }
}
#endif

@available(iOS 18, macOS 15, *)
extension View {
    @ViewBuilder
    func tabBarAccessibilityIdentifiers(_ metadata: [TabBarAccessibilityIdentifier]) -> some View {
#if os(iOS) && canImport(UIKit)
        background(TabBarAccessibilityIdentifierBridge(metadata: metadata))
#else
        self
#endif
    }
}
