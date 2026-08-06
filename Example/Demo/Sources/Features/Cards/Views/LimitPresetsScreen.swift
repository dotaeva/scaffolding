import SwiftUI
import Scaffolding

struct LimitPresetsScreen: View {
    @Environment(LimitCoordinator.self) private var coordinator

    var body: some View {
        VStack(spacing: 8) {
            ForEach([Decimal(500), 1_500, 3_000], id: \.self) { amount in
                Button {
                    // dismissCoordinator(returning:) — the presenter's
                    // `awaiting: Decimal.self` resumes with this value.
                    coordinator.finish(amount)
                } label: {
                    Text(amount, format: .currency(code: "EUR"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.white.opacity(0.07), in: .rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            Button("Custom…") {
                // A push inside the presented flow's own NavigationStack —
                // never add one manually.
                coordinator.openCustom()
            }
            .padding(.top, 8)
        }
        .padding(20)
        .frame(maxHeight: .infinity, alignment: .top)
        .background(ScreenBackground())
        .navigationTitle("Spending limit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                // Plain dismissCoordinator() → the presenter resumes with nil.
                Button("Cancel") { coordinator.cancel() }
            }
        }
    }
}
