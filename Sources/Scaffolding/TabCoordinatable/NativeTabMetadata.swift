#if os(iOS)
import SwiftUI
import UIKit

/// SwiftUI can cache TabContent metadata independently of its content. Update
/// UIKit's public metadata without changing the identity of a tab or its view.
/// A probe in each materialized tab finds only its enclosing tab controller;
/// it never searches another window or forces an inactive tab to load.
struct NativeTabMetadata: View {
    let coordinator: any TabCoordinatable

    var body: some View {
        Bridge(metadata: coordinator._resolvedTabItems.tabs.map {
            Metadata(badge: $0.badge, accessibilityIdentifier: $0.accessibilityIdentifier)
        })
    }

    struct Metadata: Equatable {
        let badge: String?
        let accessibilityIdentifier: String?
    }

    private struct Bridge: UIViewControllerRepresentable {
        let metadata: [Metadata]

        func makeUIViewController(context: Context) -> MetadataController { MetadataController() }

        func updateUIViewController(_ controller: MetadataController, context: Context) {
            controller.metadata = metadata
            controller.scheduleUpdate()
        }

        static func dismantleUIViewController(_ controller: MetadataController, coordinator: ()) {
            controller.cancelUpdate()
        }
    }

    final class MetadataController: UIViewController {
        var metadata: [Metadata] = []
        private var pendingUpdate: Task<Void, Never>?

        override func loadView() {
            view = UIView()
            view.isUserInteractionEnabled = false
            view.isAccessibilityElement = false
        }

        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            scheduleUpdate()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            applyMetadata()
        }

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            scheduleUpdate()
        }

        func cancelUpdate() { pendingUpdate?.cancel() }

        func scheduleUpdate() {
            pendingUpdate?.cancel()
            pendingUpdate = Task { @MainActor [weak self] in
                // Apply after SwiftUI commits its own TabContent update.
                await Task.yield()
                guard !Task.isCancelled else { return }
                self?.applyMetadata()
            }
        }

        private func applyMetadata() {
            guard let controller = tabBarController else { return }
            if controller.tabs.count == metadata.count {
                for (tab, value) in zip(controller.tabs, metadata) {
                    if tab.badgeValue != value.badge { tab.badgeValue = value.badge }
                    if tab.accessibilityIdentifier != value.accessibilityIdentifier {
                        tab.accessibilityIdentifier = value.accessibilityIdentifier
                    }
                }
            }
            if let children = controller.viewControllers, children.count == metadata.count {
                for (child, value) in zip(children, metadata) {
                    if child.tabBarItem.badgeValue != value.badge { child.tabBarItem.badgeValue = value.badge }
                    if child.tabBarItem.accessibilityIdentifier != value.accessibilityIdentifier {
                        child.tabBarItem.accessibilityIdentifier = value.accessibilityIdentifier
                    }
                }
            }
        }
    }
}
#endif
