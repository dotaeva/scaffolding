import SwiftUI
import Scaffolding

/// A one-screen sub-flow that returns the chosen tags.
///
/// `injectsCoordinator: false` opts it out of environment injection, so
/// `@Environment(TagPickerCoordinator.self)` finds nothing and the route
/// hands the coordinator to its screen explicitly. Useful when a screen
/// shouldn't bind itself to one specific flow. Ancestor coordinators are
/// still injected as usual.
@MainActor
@Observable
@Scaffoldable(injectsCoordinator: false)
final class TagPickerCoordinator: @MainActor FlowCoordinatable {
    var stack = FlowStack<TagPickerCoordinator>(root: .picker)

    let tags: [String]
    var selected: Set<String>

    init(selected: [String], tags: [String]) {
        self.tags = tags
        self.selected = Set(selected)
    }

    // MARK: Routes

    func picker() -> some View {
        // Init injection instead of the environment.
        TagPickerView(coordinator: self)
    }
}

// MARK: - Result

extension TagPickerCoordinator {
    func toggle(_ tag: String) {
        if selected.contains(tag) {
            selected.remove(tag)
        } else {
            selected.insert(tag)
        }
    }

    /// Hands the result to the awaiting presenter, then dismisses.
    func confirm() {
        dismissCoordinator(returning: tags.filter(selected.contains))
    }

    /// A plain dismissal resumes the presenter with `nil`, so cancellation
    /// needs no separate channel.
    func cancel() {
        dismissCoordinator()
    }
}
