import SwiftUI
import Scaffolding

// MARK: - Pushes

extension ForecastCoordinator {
    /// .distinct guards the double-tap: a second tap while the push
    /// animates would double-push the same case.
    func open(_ day: DayForecast) {
        route(to: .day(day: day), policy: .distinct)
    }

    /// Same case pushed again on purpose (day → next day chains), so the
    /// default .always policy.
    func openNext(after day: DayForecast) {
        guard day.index < 9 else { return }
        route(to: .day(day: days[day.index + 1]))
    }

    /// replaceLast: the new day takes the top slot and back skips the one
    /// it replaced — advancing without letting the user return to it.
    func skipToNext(after day: DayForecast) {
        guard day.index < 9 else { return }
        replaceLast(with: .day(day: days[day.index + 1]))
    }

    /// routeAndWait: push the picker and suspend until it pops — however
    /// it pops (its own button, the back control, a swipe).
    func chooseDay() {
        Task {
            pickedDay = nil
            await routeAndWait(to: .dayPicker)
            if let pickedDay {
                open(pickedDay)
            }
        }
    }

    /// Flow-level setRoot: swaps the root and clears the pushed stack —
    /// the Weather tab jumping to another saved city.
    func switchLocation(_ new: Location) {
        guard new != location else { return }
        location = new
        setRoot(.today(location: new))
    }
}

// MARK: - Modals

extension ForecastCoordinator {
    /// Full-screen cover on iOS; macOS has no covers, so Scaffolding
    /// renders it as a sheet there (state still reports .fullScreenCover).
    func showRadar() {
        present(.radar, as: .fullScreenCover, policy: .distinct)
    }

    /// presentAndWait: show the warning — swipe-down disabled, the user
    /// must acknowledge — and only then continue into the radar.
    func reviewAlertThenRadar() {
        Task {
            await presentAndWait(.alert, as: .sheet(
                detents: [.medium],
                dragIndicator: .hidden,
                interactiveDismissDisabled: true
            ))
            showRadar()
        }
    }
}
