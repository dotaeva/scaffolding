import SwiftUI
import Charts

/// A pushed screen inside the Stats flow: one list's numbers.
struct ListBreakdownView: View {
    let list: TodoList
    @State var viewModel: StatsViewModel

    var body: some View {
        List {
            Section {
                Gauge(value: Double(viewModel.openCount(in: list)), in: 0...10) {
                    Text("Open tasks")
                } currentValueLabel: {
                    Text("\(viewModel.openCount(in: list))")
                }
                .gaugeStyle(.accessoryLinearCapacity)
                .tint(list.color)
            }
            Section("Counts") {
                LabeledContent("Open", value: "\(viewModel.openCount(in: list))")
                LabeledContent("Flagged", value: "\(viewModel.flaggedCount(in: list))")
                LabeledContent("Overdue", value: "\(viewModel.overdueCount(in: list))")
            }
            Section {
                Text("Pushed inside the Stats flow — the tab keeps its own "
                     + "stack, so re-tapping the tab pops back here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle(list.name)
    }
}
