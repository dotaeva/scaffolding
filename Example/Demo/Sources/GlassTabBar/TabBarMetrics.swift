import SwiftUI

/// Geometry constants mirrored from expo-glass-tabs.
enum TabBarMetrics {
    static let expandedHeight: CGFloat = 58
    static let minimizedHeight: CGFloat = 44
    /// Extra horizontal inset applied to the pill when minimized (per side).
    static let minimizedInset: CGFloat = 34
    /// Outer margin between the pill and the screen edges (per side).
    static let barMargin: CGFloat = 12
    /// Inner inset between the capsule wall and the tab items.
    static let rowPadding: CGFloat = 4
    static let labelHeight: CGFloat = 13
    static let iconSize: CGFloat = 21
    /// Space between icon and label — folded into the clipped item box so it
    /// fully disappears when minimized (keeps the icon perfectly centered).
    static let itemGap: CGFloat = 2
    static let itemPadding: CGFloat = 7
    /// Item/highlight box heights — the capsule radius tracks height / 2.
    static let itemExpanded: CGFloat = iconSize + itemGap + labelHeight + itemPadding * 2
    static let itemMinimized: CGFloat = iconSize + itemPadding * 2
}
