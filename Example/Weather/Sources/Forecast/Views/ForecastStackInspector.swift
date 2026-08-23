import SwiftUI
import Scaffolding

/// Debug footer on pushed day screens: the stack-query surface and every
/// pop variant, live against the flow that owns the screen.
struct ForecastStackInspector: View {
    @Environment(ForecastCoordinator.self) private var coordinator

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stack inspector")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Group {
                Text("depth: \(coordinator.depth)")
                Text("topDestination: \(String(describing: coordinator.topDestination))")
                Text("count(of: .day): \(coordinator.count(of: .day))")
                Text("isInStack(.dayPicker): \(String(coordinator.isInStack(.dayPicker)))")
            }
            .font(.caption.monospaced())

            // pop() removes the top screen. (On an empty stack it would
            // dismiss the whole coordinator — not the case on this screen.)
            controlRow("pop()") { coordinator.pop() }
            if coordinator.depth >= 2 {
                // pop(n) removes up to n, always stopping at the root.
                controlRow("pop(2)") { coordinator.pop(2) }
                controlRow("popToRoot()") { coordinator.popToRoot() }
            }
            if coordinator.count(of: .day) >= 2 {
                // Meta-based: back to the first/last occurrence of the case.
                controlRow("popToFirst(.day)") { coordinator.popToFirst(.day) }
                controlRow("popToLast(.day)") { coordinator.popToLast(.day) }
            }
        }
        .weatherCard()
    }

    private func controlRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.bordered)
    }
}
