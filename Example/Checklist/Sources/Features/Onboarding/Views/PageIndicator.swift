import SwiftUI
import Scaffolding

/// The onboarding page dots, built from the coordinator's own tab state.
///
/// The system's paged index view offers no SwiftUI tint API — its selected
/// dot renders white, which is invisible on a light page. Deriving the
/// indicator from `tabItems` instead is the same pattern the library
/// documents for custom tab bars: chrome reads the coordinator, selection
/// stays coordinator state, and a tap routes through `select(id:)` so the
/// dots can navigate too.
struct PageIndicator: View {
    @Environment(OnboardingCoordinator.self) private var coordinator

    var body: some View {
        HStack(spacing: 8) {
            ForEach(coordinator.tabItems.tabs) { page in
                Capsule()
                    .fill(isSelected(page) ? Color.accentColor : Color.secondary.opacity(0.35))
                    .frame(width: isSelected(page) ? 24 : 8, height: 8)
                    .onTapGesture { coordinator.select(id: page.id) }
                    .accessibilityLabel(isSelected(page) ? "Current page" : "Go to page")
            }
        }
        .animation(.snappy, value: coordinator.tabItems.selectedTab)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
    }

    private func isSelected(_ page: Destination) -> Bool {
        page.id == coordinator.tabItems.selectedTab
    }
}
