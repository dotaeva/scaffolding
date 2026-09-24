import Testing
import Foundation
import Scaffolding
import ScaffoldingTesting
@testable import StinsenParity

/// The awaitable APIs suspend until their destination leaves, so each test
/// drives the call from a `Task` and resolves it from the test body.
@MainActor
@Suite("Awaited navigation")
struct AwaitedNavigationTests {
    @Test("the picker's value reaches the awaiting call")
    func pickerReturnsAValue() async {
        let toasts = ToastCenter()
        let testbed = TestbedCoordinator(toasts: toasts).activated()

        testbed.awaitPicker()
        await waitUntil { testbed.isPresentingModal }

        // descendant(ofType:) is the way into a coordinator the code under
        // test presented itself.
        testbed.descendant(ofType: PickerCoordinator.self)?.pick(2)
        await waitUntil { !testbed.queueIsEmpty }

        #expect(toasts.queue.contains { $0.message.contains("returned 2") })
    }

    @Test("cancelling the picker resumes with nil")
    func pickerCancels() async {
        let toasts = ToastCenter()
        let testbed = TestbedCoordinator(toasts: toasts).activated()

        testbed.awaitPicker()
        await waitUntil { testbed.isPresentingModal }

        // Standing in for a swipe-down.
        testbed.dismissModal()
        await waitUntil { !testbed.queueIsEmpty }

        #expect(toasts.queue.contains { $0.message.contains("cancelled") })
    }

    @Test("a created todo reaches the awaiting present call")
    func createTodoReturnsATodo() async {
        let toasts = ToastCenter()
        let store = TodosStore(
            user: .preview,
            defaults: UserDefaults(suiteName: "test.\(UUID().uuidString)")!
        )
        let todos = TodosCoordinator(store: store, toasts: toasts).activated()
        let before = store.all.count

        todos.addTodo()
        await waitUntil { todos.isPresentingModal }

        todos.descendant(ofType: CreateTodoCoordinator.self)?.create(name: "Written by a test")
        await waitUntil { store.all.count > before }

        #expect(store.all.last?.name == "Written by a test")
    }
}

private extension TestbedCoordinator {
    /// `waitUntil` spins on yields, so the assertions wait on the toast
    /// the resumed call posts rather than on wall clock.
    var queueIsEmpty: Bool { toasts.queue.isEmpty }
}
