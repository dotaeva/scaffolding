import SwiftUI
import Scaffolding

/// Pushed by chooseDay(), which suspends in routeAndWait until this pops.
/// The screen writes the result into coordinator state and pops itself —
/// backing out without choosing resumes the caller just the same.
struct DayPickerScreen: View {
    @Environment(ForecastCoordinator.self) private var coordinator

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(coordinator.days) { day in
                    DayRow(day: day) {
                        coordinator.pickedDay = day
                        coordinator.pop()
                    }
                }
            }
            .weatherCard()
            .padding(16)
        }
        .navigationTitle("Jump to a day")
        .skyBackground(coordinator.todayCondition)
    }
}
