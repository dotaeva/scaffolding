import SwiftUI

/// The `parity://` URL to paste into Safari, with a copy button — a demo
/// nobody can run is not a demo.
struct DeepLinkRow: View {
    let store: TodosStore

    @State private var didCopy = false

    private var url: String {
        "parity://todo/\(store.all.first?.name ?? "Buy milk")"
    }

    var body: some View {
        LabeledContent("URL") {
            HStack(spacing: 10) {
                Text(url)
                    .font(.callout.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .textSelection(.enabled)

                Button(didCopy ? "Copied" : "Copy") {
                    copy(url)
                    withAnimation(.snappy) { didCopy = true }
                }
            }
        }
        .task(id: didCopy) {
            guard didCopy else { return }
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.snappy) { didCopy = false }
        }
    }

    private func copy(_ string: String) {
        UIPasteboard.general.string = string
    }
}
