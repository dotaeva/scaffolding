/*
Scaffolding port of Apple's "Landmarks: Building an app with Liquid Glass"
sample. See LICENSE.txt for the sample's licensing information.

Abstract:
The app root: a SplitCoordinatable that replaces LandmarksSplitView.
*/

import SwiftUI
import Observation
import Scaffolding

/// The app root. Replaces the sample's `LandmarksSplitView`: the sidebar
/// page selection becomes detail-column replacement on a coordinator, and
/// the `NavigationPath` that lived in `ModelData` disappears — each page
/// is a flow coordinator that owns its own stack.
@MainActor @Observable @Scaffoldable
final class LandmarksSplitCoordinator: @MainActor SplitCoordinatable {
    var columns = SplitColumns<LandmarksSplitCoordinator>(
        sidebar: .sidebar,
        detail: .landmarks,
        preferredCompactColumn: .detail   // matches the sample's start column
    )

    let modelData: ModelData

    /// Domain state: which sidebar page is showing. The sidebar reads it
    /// for the native selection highlight.
    private(set) var selectedPage: NavigationOptions = .landmarks

    init(modelData: ModelData) {
        self.modelData = modelData
    }

    // MARK: Routes
    // Routes must be declared in the class body — @Scaffoldable scans only
    // the class declaration, never extensions.

    func sidebar() -> some View { SidebarView() }
    func landmarks() -> any Coordinatable { LandmarksPageCoordinator(modelData: modelData) }
    func map() -> some View { MapView() }
    func collections() -> any Coordinatable { CollectionsCoordinator(modelData: modelData) }
}

// MARK: - Page selection

extension LandmarksSplitCoordinator {
    /// Sidebar row tap. Re-selecting the page that is already showing
    /// keeps its flow — and anything pushed inside it.
    func select(_ page: NavigationOptions) {
        guard selectedPage != page else { return }
        selectedPage = page

        switch page {
        case .landmarks: setDetail(.landmarks)
        case .map: setDetail(.map)
        case .collections: setDetail(.collections)
        }
    }
}

// MARK: - Chrome

extension LandmarksSplitCoordinator {
    /// The cross-cutting chrome the sample attached to its
    /// `NavigationSplitView`: global search, the landmark inspector, and
    /// the badges drawer. `customize` wraps the coordinator's split view,
    /// so the placement is identical. (In an extension the macro never
    /// sees this — no @ScaffoldingIgnored needed.)
    func customize(_ view: AnyView) -> some View {
        @Bindable var modelData = modelData

        return view
            .searchable(text: $modelData.searchString, prompt: "Search")
            .inspector(isPresented: $modelData.isLandmarkInspectorPresented) {
                if let landmark = modelData.selectedLandmark {
                    LandmarkDetailInspectorView(
                        landmark: landmark,
                        inspectorIsPresented: $modelData.isLandmarkInspectorPresented
                    )
                } else {
                    EmptyView()
                }
            }
            .showsBadges()
    }
}
