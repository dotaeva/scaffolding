//
//  TabBarAccessibilityIdentifier.swift
//  Scaffolding
//
//  Accessibility metadata for rendered tab bar controls.
//

import Foundation

/// Accessibility metadata applied to rendered tab bar controls by matching their labels.
///
/// `matchingLabels` should contain the visible or accessibility labels rendered by the tab item and should be unique
/// among visible tabs.
/// Empty labels are stored, but do not participate in UIKit tab-bar matching.
@available(iOS 18, macOS 15, *)
public struct TabBarAccessibilityIdentifier: Equatable, Sendable {
    /// The accessibility identifier to apply to matching rendered tab controls.
    public let identifier: String
    /// Labels that identify the rendered tab controls without relying on tab order.
    public let matchingLabels: [String]

    public init(identifier: String, matchingLabels: [String]) {
        self.identifier = identifier
        self.matchingLabels = matchingLabels
    }
}

@available(iOS 18, macOS 15, *)
extension TabBarAccessibilityIdentifier {
    func matches(renderedLabel: String) -> Bool {
        let renderedLabel = renderedLabel.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !renderedLabel.isEmpty else { return false }

        return matchingLabels.contains { matchingLabel in
            let matchingLabel = matchingLabel.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !matchingLabel.isEmpty else { return false }

            return renderedLabel.localizedCaseInsensitiveContains(matchingLabel)
                || matchingLabel.localizedCaseInsensitiveContains(renderedLabel)
        }
    }
}
