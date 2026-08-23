import SwiftUI
import Scaffolding

/// Split-view column controls. Settings is presented as a sheet *on* the
/// split coordinator there, so the ancestor is in the environment; on the
/// tab layout the section simply doesn't render.
struct SettingsSplitSection: View {
    @Environment(WeatherSplitCoordinator.self) private var split: WeatherSplitCoordinator?

    var body: some View {
        if let split {
            Section("Split View") {
                LabeledContent("isSidebarVisible", value: String(split.isSidebarVisible))
                LabeledContent(
                    "detailDestination",
                    value: String(describing: split.detailDestination)
                )
                Button("Toggle Sidebar") {
                    split.toggleSidebar()
                }
                Button("Detail Only") {
                    split.setColumnVisibility(.detailOnly)
                }
                Button("All Columns") {
                    split.setColumnVisibility(.all)
                }
            }
        }
    }
}
