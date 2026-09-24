import SwiftUI
import AtlasDomain

public extension EnvironmentValues {
    @Entry var atlasSession: AtlasSessionContext?
}

/// Shared behavior only. Form supplies each platform's typography, spacing, and colors.
public struct AtlasForm<Content: View>: View {
    @Environment(\.atlasSession) private var session
    private let content: Content

    public init(@ViewBuilder content: () -> Content) { self.content = content() }

    public var body: some View {
        ScrollViewReader { proxy in
            Form {
                AtlasFeedbackSection()
                content
            }
            .formStyle(.grouped)
            .onChange(of: session?.message?.id) { _, id in
                if id != nil { proxy.scrollTo("atlas.feedback", anchor: .top) }
            }
        }
    }
}

public struct InlineNavigationTitle: ViewModifier {
    public init() {}
    public func body(content: Content) -> some View {
        #if os(iOS)
        content.navigationBarTitleDisplayMode(.inline)
        #else
        content
        #endif
    }
}
