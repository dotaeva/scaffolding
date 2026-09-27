import SwiftUI
import Observation
import Scaffolding

@MainActor @Observable @Scaffoldable
final class ResultFlow: FlowCoordinatable {
    var stack = FlowStack<ResultFlow>(root: .screen)
    func screen() -> some View { ResultScreen() }
    func child() -> any Coordinatable { ResultFlow() }
}

@MainActor @Observable @Scaffoldable
final class ResultRoot: RootCoordinatable {
    var root = Root<ResultRoot>(root: .child)
    func child() -> any Coordinatable { ResultFlow() }
}

@MainActor @Observable @Scaffoldable
final class ResultTabs: TabCoordinatable {
    var tabItems = TabItems<ResultTabs>(tabs: [.child])
    func child() -> any Coordinatable { ResultFlow() }
}

@MainActor @Observable @Scaffoldable
final class ResultSplit: SplitCoordinatable {
    var columns = SplitColumns<ResultSplit>(sidebar: .child, detail: .child)
    func child() -> any Coordinatable { ResultFlow() }
}

struct ResultScreen: View {
    @Environment(\.destination) private var destination
    @Environment(\.dismiss) private var dismiss
    @Environment(ResultFlow.self) private var coordinator

    var body: some View {
        Button("Choose") { destination.dismiss(returning: "chosen") }
        Button("Pop") { coordinator.pop() }
        Button("Close destination") { destination.dismiss() }
        Button("Native dismiss") { dismiss() }
    }
}

@MainActor
func modernNavigation(
    flow: ResultFlow, root: ResultRoot, tabs: ResultTabs, split: ResultSplit
) async {
    // Existing synchronous calls must remain valid inside async code too.
    flow.route(to: .screen)
    flow.present(.child)
    _ = flow.route(to: .child, expecting: ResultFlow.self)
    _ = flow.present(.child, expecting: ResultFlow.self)
    _ = flow.setRoot(.child, expecting: ResultFlow.self)
    _ = flow.popToFirst(.child, expecting: ResultFlow.self)
    _ = flow.popToLast(.child, expecting: ResultFlow.self)
    _ = await flow.route(to: .screen, awaiting: String.self)
    _ = await flow.present(.child, awaiting: Void.self)

    root.present(.child)
    _ = root.present(.child, expecting: ResultFlow.self)
    _ = root.setRoot(.child, expecting: ResultFlow.self)
    _ = await root.present(.child, awaiting: String.self)

    tabs.present(.child)
    _ = tabs.present(.child, expecting: ResultFlow.self)
    _ = tabs.selectFirstTab(.child, expecting: ResultFlow.self)
    _ = tabs.selectLastTab(.child, expecting: ResultFlow.self)
    _ = tabs.select(index: 0, expecting: ResultFlow.self)
    _ = tabs.select(id: UUID(), expecting: ResultFlow.self)
    _ = tabs.appendTab(.child, expecting: ResultFlow.self)
    _ = tabs.insertTab(.child, at: 0, expecting: ResultFlow.self)
    _ = await tabs.present(.child, awaiting: String.self)

    split.present(.child)
    _ = split.present(.child, expecting: ResultFlow.self)
    _ = split.setSidebar(.child, expecting: ResultFlow.self)
    _ = split.setContent(.child, expecting: ResultFlow.self)
    _ = split.setDetail(.child, expecting: ResultFlow.self)
    _ = await split.present(.child, awaiting: String.self)
}

// Combined overloads navigate synchronously, including outside async contexts.
@MainActor
func combinedNavigation(
    flow: ResultFlow, root: ResultRoot, tabs: ResultTabs, split: ResultSplit
) {
    let push = flow.route(to: .child, policy: .distinct,
                          expecting: ResultFlow.self, awaiting: String.self)
    let modal = flow.present(.child, as: .fullScreenCover,
                             expecting: ResultFlow.self, awaiting: Void.self)
    let rootModal = root.present(.child, expecting: ResultFlow.self, awaiting: String.self)
    let tabModal = tabs.present(.child, expecting: ResultFlow.self, awaiting: String.self)
    let splitModal = split.present(.child, expecting: ResultFlow.self, awaiting: String.self)
    push.coordinator?.route(to: .screen)
    modal.coordinator?.route(to: .screen)
    Task { @MainActor in
        let _: String? = await push.result()
        let _: Void? = await modal.result()
        let _: String? = await rootModal.result()
        let _: String? = await tabModal.result()
        let _: String? = await splitModal.result()
    }
}
