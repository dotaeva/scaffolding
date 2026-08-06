import SwiftUI

/// One tab: icon + label that fades and clips away when minimized.
struct GlassTabButton: View {
    let item: GlassTabItem
    let index: Int
    let theme: GlassTabBarTheme
    let model: GlassTabBarModel
    let onSelect: (Int) -> Void

    var body: some View {
        VStack(spacing: TabBarMetrics.itemGap) {
            // Inactive glyph underneath, active glyph crossfading on top.
            // Tint follows the sliding highlight, not navigation focus:
            // whatever the pill is over lights up — live while scrubbing,
            // traveling on taps.
            ZStack {
                glyph(tint: theme.inactiveTint)
                glyph(tint: theme.activeTint)
                    .modifier(HighlightProximityFade(slideIndex: model.slideIndex, index: index))
            }
            .overlay(alignment: .topTrailing) {
                if let badge = item.badge {
                    Text(badge)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(.red, in: .capsule)
                        .offset(x: 10, y: -4)
                }
            }
            ZStack {
                label(tint: theme.inactiveTint)
                label(tint: theme.activeTint)
                    .modifier(HighlightProximityFade(slideIndex: model.slideIndex, index: index))
            }
            // The label collapses into the icon: it scales toward its top
            // edge (the glyph above) while fading, riding the same minimize
            // spring as the bar geometry. No clipping — by the time the
            // shrinking box would crop it, it has already dissolved.
            .scaleEffect(model.isMinimized ? 0.4 : 1, anchor: .top)
            .opacity(model.isMinimized ? 0 : 1)
        }
        .padding(.top, TabBarMetrics.itemPadding)
        // Height is animated explicitly (not derived from children) so the
        // icon stays perfectly centered every frame.
        .frame(
            height: model.isMinimized ? TabBarMetrics.itemMinimized : TabBarMetrics.itemExpanded,
            alignment: .top
        )
        .frame(maxWidth: .infinity)
        .contentShape(.rect)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.label)
        .accessibilityAddTraits(model.selectedIndex == index ? [.isButton, .isSelected] : .isButton)
        // The bar's gesture consumes touches; this keeps VoiceOver and
        // Switch Control activation working.
        .accessibilityAction {
            onSelect(index)
        }
    }

    private func glyph(tint: Color) -> some View {
        Image(systemName: item.systemImage)
            .font(.system(size: TabBarMetrics.iconSize, weight: .semibold))
            .foregroundStyle(tint)
            .frame(height: TabBarMetrics.iconSize)
    }

    private func label(tint: Color) -> some View {
        Text(item.label)
            .font(.system(size: 9.5, weight: .semibold))
            .lineLimit(1)
            .foregroundStyle(tint)
            .frame(height: TabBarMetrics.labelHeight)
    }
}
