import SwiftUI

struct AboutScreen: View {
    var body: some View {
        List {
            Section("This example") {
                Text("A Weather-style app that exercises the whole Scaffolding library on iOS, iPadOS, and macOS from one target.")
            }
            Section("Where to look") {
                row("cloud.sun.fill", "ForecastCoordinator — pushes, policies, replaceLast, routeAndWait, every pop")
                row("list.star", "LocationsCoordinator — child-coordinator pushes, awaiting sub-flows, view-only sheets")
                row("square.split.2x1", "WeatherSplitCoordinator — columns, visibility, split modals (iPad/macOS)")
                row("square.grid.2x2", "MainTabCoordinator — tab tuples, shouldSelect, badges, dynamic tabs (iPhone)")
                row("arrow.triangle.2.circlepath", "AppCoordinator — root swaps, deep links, state restoration")
            }
        }
        .navigationTitle("About")
    }

    private func row(_ symbol: String, _ text: String) -> some View {
        Label {
            Text(text).font(.callout)
        } icon: {
            Image(systemName: symbol)
        }
    }
}
