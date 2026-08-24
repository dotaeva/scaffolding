import SwiftUI
import Scaffolding

/// A view-only modal: no coordinator inside it, and no navigation
/// container either — so the close control is a plain overlay rather than
/// a toolbar item, and it renders only because this view *is* the
/// presented destination.
struct FocusSessionView: View {
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    let todo: Todo?

    var body: some View {
        ZStack {
            Color.groupedBackground
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.tint)
                    .symbolEffect(.breathe)
                Text(todo?.title ?? "Nothing to focus on")
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
                if let todo, let due = todo.dueDescription {
                    Text("Due \(due)")
                        .foregroundStyle(.secondary)
                }
                Text("Presented as a cover on iOS; macOS has no covers, so "
                     + "Scaffolding shows it as a sheet — the state still "
                     + "reports .\(String(describing: destination.routeType)).")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 360)
            }
            .padding(32)
        }
        .overlay(alignment: .topTrailing) {
            Button("Done") { dismiss() }
                .buttonStyle(.bordered)
                .padding(20)
        }
        .sheetSizing(minHeight: 380, idealHeight: 460)
    }
}
