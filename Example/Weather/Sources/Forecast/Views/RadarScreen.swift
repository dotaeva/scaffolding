import SwiftUI
import Scaffolding

/// Fake precipitation radar. Rendered two ways: a full-screen cover from
/// the forecast flow (a sheet on macOS — no covers there) and the dynamic
/// Radar *tab* on iPhone.
///
/// A view-only modal has no NavigationStack of its own (and must never
/// create one), so the close control is a plain overlay. It renders only
/// in the modal case — `\.destination.routeType` distinguishes the cover
/// from the tab, where the same screen shows no chrome at all.
struct RadarScreen: View {
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss

    @State private var sweep = false

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.10, blue: 0.16)
                .ignoresSafeArea()
            ForEach(1..<5) { ring in
                Circle()
                    .stroke(.green.opacity(0.25), lineWidth: 1)
                    .frame(width: CGFloat(ring) * 90)
            }
            Rectangle()
                .fill(
                    AngularGradient(
                        colors: [.clear, .green.opacity(0.5)],
                        center: .center,
                        angle: .degrees(0)
                    )
                )
                .frame(width: 360, height: 360)
                .clipShape(.circle)
                .rotationEffect(.degrees(sweep ? 360 : 0))
                .animation(.linear(duration: 4).repeatForever(autoreverses: false), value: sweep)
            Text("No precipitation expected")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .offset(y: 210)
        }
        .overlay(alignment: .topTrailing) {
            if destination.routeType.isModal {
                Button("Close") { dismiss() }
                    .buttonStyle(.bordered)
                    .padding(16)
            }
        }
        .onAppear { sweep = true }
    }
}
