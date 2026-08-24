import SwiftUI
import Scaffolding

/// Shell-specific controls. Both reads are optional, so the section shows
/// whichever shell is actually above this flow — tabs on iPhone, columns
/// on iPad and Mac.
struct SettingsShellSection: View {
    @Environment(MainTabCoordinator.self) private var tabs: MainTabCoordinator?
    @Environment(MainSplitCoordinator.self) private var split: MainSplitCoordinator?
    @Environment(TodoStore.self) private var store

    var body: some View {
        if let tabs {
            Section("Tabs") {
                Toggle("Stats tab", isOn: statsBinding(tabs))
                LabeledContent("isInTabItems(.stats)", value: String(tabs.isInTabItems(.stats)))
                LabeledContent("Today badge", value: tabs.badge(for: .today) ?? "none")
                Button("Refresh Badge") { tabs.refreshBadge() }
            }
        }
        if let split {
            Section("Columns") {
                LabeledContent("detailDestination", value: caseLabel(split.detailDestination))
                LabeledContent("isSidebarVisible", value: String(split.isSidebarVisible))
                Toggle("Focus mode (no task column)", isOn: focusBinding(split))
                Button("Show All Columns") { split.setColumnVisibility(.all) }
                Button("Detail Only") { split.setColumnVisibility(.detailOnly) }
            }
        }
    }

    private func statsBinding(_ tabs: MainTabCoordinator) -> Binding<Bool> {
        Binding(
            get: { tabs.isInTabItems(.stats) },
            set: { tabs.setStatsTab(enabled: $0) }
        )
    }

    private func focusBinding(_ split: MainSplitCoordinator) -> Binding<Bool> {
        Binding(
            get: { split.isFocusMode },
            set: { _ in split.toggleFocusMode() }
        )
    }
}
