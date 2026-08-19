import SwiftUI
import Scaffolding

struct PlanetsTabBar: View {
    @Environment(AppCoordinator.self) private var coordinator

    var body: some View {
        HStack {
            button(.planets, icon: "globe")
            button(.favorites, icon: "star")
        }
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func button(
        _ tab: AppCoordinator.Destinations.Meta,
        icon: String
    ) -> some View {
        Button {
            // A custom bar tap is programmatic selection, which bypasses
            // shouldSelect — consult the hook yourself to keep the guard.
            let isReselection = isSelected(tab)
            if coordinator.shouldSelect(tab: tab, isReselection: isReselection),
               !isReselection {
                coordinator.selectFirstTab(tab)
            }
        } label: {
            Image(systemName: icon)
                .foregroundStyle(isSelected(tab) ? Color.accentColor : .secondary)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .topTrailing) {
                    if let badge = coordinator.badge(for: tab) {
                        Text(badge).font(.caption2).padding(4)
                    }
                }
        }
        // A custom bar renders no tab bar item, so carry the coordinator's
        // identifier over to the button that replaces it.
        .accessibilityIdentifier(
            coordinator.tabAccessibilityIdentifier(for: tab) ?? "",
            isEnabled: coordinator.tabAccessibilityIdentifier(for: tab) != nil
        )
    }

    private func isSelected(_ tab: AppCoordinator.Destinations.Meta) -> Bool {
        coordinator.tabItems.tabs
            .first { $0.id == coordinator.tabItems.selectedTab }
            .flatMap { $0.meta as? AppCoordinator.Destinations.Meta } == tab
    }
}
