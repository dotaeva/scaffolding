import SwiftUI
import Charts
import Scaffolding

/// Swift Charts, straight out of the box: a bar chart per weekday and a
/// donut of open tasks per list.
struct StatsView: View {
    @Environment(StatsCoordinator.self) private var coordinator
    @State var viewModel: StatsViewModel

    var body: some View {
        List {
            Section {
                HStack {
                    StatTile(title: "Done", value: "\(viewModel.completedCount)", tint: .green)
                    StatTile(title: "Open", value: "\(viewModel.openCount)", tint: .blue)
                    StatTile(
                        title: "Rate",
                        value: viewModel.completionRate.formatted(.percent.precision(.fractionLength(0))),
                        tint: .accentColor
                    )
                }
            }

            Section("Completed by weekday") {
                Chart(viewModel.weekly) { day in
                    BarMark(x: .value("Day", day.label), y: .value("Done", day.completed))
                        .foregroundStyle(.tint)
                        .cornerRadius(4)
                }
                .frame(height: 180)
            }

            Section("Open tasks by list") {
                Chart(viewModel.shares) { share in
                    SectorMark(
                        angle: .value("Open", max(share.open, 0)),
                        innerRadius: .ratio(0.6),
                        angularInset: 1.5
                    )
                    // Styling *by value* gives the chart a real legend;
                    // the scale below keeps each list's own colour.
                    .foregroundStyle(by: .value("List", share.name))
                    .annotation(position: .overlay) {
                        if share.open > 0 {
                            Text("\(share.open)")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    }
                }
                .chartForegroundStyleScale(
                    domain: viewModel.shares.map(\.name),
                    range: viewModel.shares.map { $0.colorName.color }
                )
                .chartLegend(position: .bottom, spacing: 12)
                .frame(height: 220)
            }

            Section("Per list") {
                ForEach(viewModel.lists) { list in
                    Button { coordinator.open(list) } label: {
                        Label(list.name, systemImage: list.symbol)
                            .foregroundStyle(.primary)
                            .badge(viewModel.openCount(in: list))
                    }
                }
            }
        }
        .navigationTitle("Stats")
    }
}

#Preview {
    StatsCoordinator(store: TodoStore()).view
        .environment(TodoStore())
}
