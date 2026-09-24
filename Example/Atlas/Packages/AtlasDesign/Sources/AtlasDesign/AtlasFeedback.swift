import SwiftUI
import AtlasDomain

/// A normal form/list section keeps feedback below navigation and toolbars.
public struct AtlasFeedbackSection: View {
    @Environment(\.atlasSession) private var session
    public init() {}

    public var body: some View {
        if let session, let message = session.message {
            Section {
                HStack(alignment: .top) {
                    Text(message.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button { session.dismissMessage() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Dismiss message")
                    .accessibilityIdentifier("notice.dismiss")
                }
                if let action = message.action {
                    Button(action.title) { session.performMessageAction() }
                        .accessibilityIdentifier("notice.action")
                }
            }.id("atlas.feedback")
        }
    }
}
