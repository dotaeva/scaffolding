import SwiftUI

/// Floating liquid-glass tab bar with Revolut-style minimize-on-scroll,
/// a sliding highlight, and finger scrubbing. Pure-SwiftUI port of
/// expo-glass-tabs' `GlassTabBar`.
///
/// Self-contained bottom chrome: overlay it full-bleed (no alignment or
/// padding needed) — it reads the safe-area inset itself and anchors the
/// capsule above the home indicator. Transparent regions pass touches
/// through to the content behind.
struct GlassTabBar: View {
    let items: [GlassTabItem]
    let model: GlassTabBarModel
    var theme = GlassTabBarTheme()
    /// Haptic tick while the scrub crosses tab boundaries.
    var hapticsEnabled = true

    /// Width available to the *expanded* bar — measured outside the animated
    /// minimize inset, so it never changes mid-animation. All animated
    /// geometry derives from it analytically; measuring the animated bar
    /// itself would write state every frame of the spring and re-evaluate
    /// the whole body, stuttering the animation.
    @State private var availableWidth: CGFloat = 0
    @State private var drag = DragPhase.idle
    @State private var scrubTick = 0
    @State private var lastTicked = -1

    /// Mirrors the pan/tap race from the gesture-handler version: the pan
    /// activates past 6pt of horizontal travel, fails past 14pt of vertical
    /// travel, and anything that never activates is treated as a tap.
    private enum DragPhase: Equatable {
        case idle, scrubbing, failed
    }

    private func itemWidth(minimized: Bool) -> CGFloat {
        let barWidth = minimized ? availableWidth - TabBarMetrics.minimizedInset * 2 : availableWidth
        return max((barWidth - TabBarMetrics.rowPadding * 2) / CGFloat(max(items.count, 1)), 1)
    }

    private var itemHeight: CGFloat {
        model.isMinimized ? TabBarMetrics.itemMinimized : TabBarMetrics.itemExpanded
    }

    var body: some View {
        GeometryReader { geometry in
            // The pill hugs the home indicator; on inset-less devices it
            // keeps a fixed margin — same formula as the source library.
            let bottomOffset = max(geometry.safeAreaInsets.bottom - 16, 12)
            capsule
                .padding(.horizontal, TabBarMetrics.barMargin)
                .padding(.bottom, bottomOffset)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(.container, edges: .bottom)
        }
    }

    private var capsule: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(theme.highlight)
                .frame(width: itemWidth(minimized: model.isMinimized), height: itemHeight)
                .modifier(HighlightSlideEffect(
                    slideIndex: model.slideIndex,
                    itemWidth: itemWidth(minimized: model.isMinimized)
                ))
            HStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    GlassTabButton(
                        item: item,
                        index: index,
                        theme: theme,
                        model: model,
                        onSelect: select
                    )
                }
            }
            .padding(.horizontal, TabBarMetrics.rowPadding)
        }
        .frame(height: model.isMinimized ? TabBarMetrics.minimizedHeight : TabBarMetrics.expandedHeight)
        .frame(maxWidth: .infinity)
        // The capsule shape lives on the glass itself: iOS 26 glass renders
        // its own corner configuration (true squircle + rim lighting).
        .glassEffect(.regular.tint(theme.glassTint), in: .capsule)
        .contentShape(.capsule)
        .gesture(scrubGesture)
        .sensoryFeedback(.selection, trigger: scrubTick) { _, _ in hapticsEnabled }
        // Revolut-style: the pill shrinks in both dimensions when minimized.
        .padding(.horizontal, model.isMinimized ? TabBarMetrics.minimizedInset : 0)
        .onGeometryChange(for: CGFloat.self, of: \.size.width) { availableWidth = $0 }
        // Covers programmatic navigation too (deep links). While scrubbing,
        // the finger owns the highlight — never fight it with a spring.
        .onChange(of: model.selectedIndex) { _, index in
            guard !model.isDragging else { return }
            withAnimation(.tabSlide) {
                model.slideIndex = CGFloat(index)
            }
        }
    }

    /// Scrubbing: the highlight tracks the finger 1:1 while dragging (no
    /// spring — it must feel attached), haptic ticks fire on boundary
    /// crossings, and navigation happens only on release.
    private var scrubGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if drag == .idle {
                    if abs(value.translation.height) > 14 {
                        drag = .failed
                    } else if abs(value.translation.width) > 6 {
                        drag = .scrubbing
                        model.isDragging = true
                        lastTicked = Int(model.slideIndex.rounded())
                        model.setMinimized(false)
                    }
                }
                guard drag == .scrubbing else { return }

                let index = fractionalIndex(atX: value.location.x)
                model.slideIndex = index

                let rounded = Int(index.rounded())
                if rounded != lastTicked {
                    lastTicked = rounded
                    scrubTick += 1
                }
            }
            .onEnded { value in
                defer { drag = .idle }
                switch drag {
                case .failed:
                    break
                case .scrubbing:
                    let rounded = Int(model.slideIndex.rounded())
                    withAnimation(.tabSlide) {
                        model.slideIndex = CGFloat(rounded)
                    }
                    // Navigation only on release — switching screens live
                    // while scrubbing makes the content jump under the finger.
                    model.isDragging = false
                    model.select(rounded)
                case .idle:
                    // Never activated: it was a tap.
                    select(Int(fractionalIndex(atX: value.location.x).rounded()))
                }
            }
    }

    private func select(_ index: Int) {
        withAnimation(.tabSlide) {
            model.slideIndex = CGFloat(index)
        }
        model.select(index)
    }

    /// Continuous finger x → fractional tab index, centered under the finger.
    /// Uses expanded metrics: touching the bar immediately expands it.
    private func fractionalIndex(atX x: CGFloat) -> CGFloat {
        let raw = (x - TabBarMetrics.rowPadding) / itemWidth(minimized: false) - 0.5
        return min(max(raw, 0), CGFloat(items.count - 1))
    }
}
