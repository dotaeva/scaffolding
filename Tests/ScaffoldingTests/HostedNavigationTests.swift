#if os(macOS) || os(iOS)
import SwiftUI
import Testing
import ScaffoldingTesting
@testable import Scaffolding
#if os(macOS)
import AppKit
#else
import UIKit

@MainActor
private final class ReadyHostingController: UIHostingController<AnyView> {
    var hasAppeared = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hasAppeared = true
    }
}
#endif

@MainActor @Observable
final class HostedAppearances {
    var tokens: [String: UUID] = [:]
    var counts: [String: Int] = [:]
}

private struct HostedStatefulView: View {
    let name: String
    let appearances: HostedAppearances
    @State private var token = UUID()
    var body: some View {
        Text(name)
            .onAppear {
                appearances.tokens[name] = token
                appearances.counts[name, default: 0] += 1
            }
    }
}

private struct HostedRootStateView: View {
    let record: Int
    let appearances: HostedAppearances
    @State private var token = UUID()

    var body: some View {
        Text("Record \(record)")
            .onChange(of: record, initial: true) {
                appearances.tokens["record-\(record)"] = token
            }
    }
}

@MainActor @Observable @Scaffoldable
final class HostedTabs: TabCoordinatable {
    var tabItems = TabItems<HostedTabs>(tabs: [.form, .other])
    let appearances = HostedAppearances()
    func form() -> (some View, some View) {
        (HostedStatefulView(name: "form", appearances: appearances), Label("Form", systemImage: "pencil"))
    }
    func other() -> (some View, some View) { (Text("Other"), Label("Other", systemImage: "star")) }
}

@MainActor @Observable @Scaffoldable
final class HostedFlow: FlowCoordinatable {
    var stack: FlowStack<HostedFlow>
    let appearances = HostedAppearances()
    init(seeded: Bool = false) { stack = FlowStack(root: .home, pushing: seeded ? [.detail] : []) }
    func home() -> some View { HostedStatefulView(name: "home", appearances: appearances) }
    func detail() -> some View { HostedStatefulView(name: "detail", appearances: appearances) }
    func modal(name: String) -> some View { HostedStatefulView(name: name, appearances: appearances) }
    func child(_ child: any Coordinatable) -> any Coordinatable { child }
    func statefulRoot(record: Int) -> some View { HostedRootStateView(record: record, appearances: appearances) }
}

@MainActor
private final class HostedWindow {
#if os(macOS)
    let window: NSWindow
    init(_ view: some View) {
        _ = NSApplication.shared
        window = NSWindow(contentRect: NSRect(x: -2000, y: -2000, width: 700, height: 500), styleMask: [.titled], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = NSHostingView(rootView: view)
        window.orderFront(nil)
    }
    func close() { window.close() }
    var isReady: Bool { true }
#else
    let window: UIWindow
    var isReady: Bool { (window.rootViewController as? ReadyHostingController)?.hasAppeared == true }
    init(_ view: some View) {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            window = UIWindow(windowScene: scene)
        } else {
            window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        }
        window.rootViewController = ReadyHostingController(rootView: AnyView(view))
        window.makeKeyAndVisible()
    }
    func close() { window.isHidden = true; window.rootViewController = nil }
    func controller<T: UIViewController>(ofType: T.Type) -> T? {
        func search(_ controller: UIViewController) -> T? {
            if let found = controller as? T { return found }
            for child in controller.children { if let found = search(child) { return found } }
            if let presented = controller.presentedViewController { return search(presented) }
            return nil
        }
        return window.rootViewController.flatMap(search)
    }
#endif
}

@MainActor @Observable
private final class HostedChromeReadings {
    var owners: [ObjectIdentifier?] = []
    var ancestors: [ObjectIdentifier?] = []
}

private struct HostedCoordinatorChrome: View {
    @Environment(HostedCustomizedFlow.self) private var owner: HostedCustomizedFlow?
    @Environment(HostedFlow.self) private var ancestor: HostedFlow?
    let readings: HostedChromeReadings

    var body: some View {
        Text("Chrome")
            .onAppear {
                readings.owners.append(owner.map(ObjectIdentifier.init))
                readings.ancestors.append(ancestor.map(ObjectIdentifier.init))
            }
    }
}

@MainActor @Observable @Scaffoldable
private final class HostedCustomizedFlow: FlowCoordinatable {
    var stack = FlowStack<HostedCustomizedFlow>(root: .home)
    let readings = HostedChromeReadings()
    func home() -> some View { Text("Home") }
    func detail() -> some View { Text("Detail") }
}

private extension HostedCustomizedFlow {
    func customize(_ view: AnyView) -> some View {
        view.overlay { HostedCoordinatorChrome(readings: readings) }
    }
}

@MainActor @Suite("Hosted navigation", .serialized, .timeLimit(.minutes(1)))
struct HostedNavigationTests {
    @Test func sharedStackCustomizationReceivesOwnerAndAncestors() async {
        let outer = HostedFlow()
        let child = HostedCustomizedFlow()
        outer.route(to: .child(child))
        let host = HostedWindow(outer.view)
        defer { host.close() }
        guard await waitUntil({ !child.readings.owners.isEmpty }, timeout: .seconds(3)) else { return }
        let rootReadings = child.readings.owners.count

        child.route(to: .detail)
        guard await waitUntil({ child.readings.owners.count > rootReadings }, timeout: .seconds(3)) else { return }

        #expect(child.readings.owners.allSatisfy { $0 == ObjectIdentifier(child) })
        #expect(child.readings.ancestors.allSatisfy { $0 == ObjectIdentifier(outer) })
    }

    @Test(arguments: [false, true])
    func replacingRootResetsViewState(sharesStack: Bool) async throws {
        let child = HostedFlow()
        child.setRoot(.statefulRoot(record: 1))
        let outer = HostedFlow()
        if sharesStack { outer.route(to: .child(child)) }
        let host = HostedWindow(sharesStack ? outer.view : child.view)
        defer { host.close() }
        guard await waitUntil({ child.appearances.tokens["record-1"] != nil }, timeout: .seconds(3)) else { return }
        var previous = try #require(child.appearances.tokens["record-1"])

        // Changing the payload and replacing the exact same route both create
        // a new screen lifetime. The enclosing pushed child must stay attached.
        for record in [2, 2] {
            withNavigationTransaction(animation: .disabled) {
                child.setRoot(.statefulRoot(record: record))
            }
            guard await waitUntil({
                child.appearances.tokens["record-\(record)"].map { $0 != previous } == true
            }, timeout: .seconds(3)) else { return }
            previous = try #require(child.appearances.tokens["record-\(record)"])
            if sharesStack {
                #expect(child.parent === outer)
                #expect(outer.bindingStack(for: .push).wrappedValue.count == 1)
            }
        }
    }

    @Test func metadataUpdatesKeepStateAndUpdateNativeTabs() async throws {
        let tabs = HostedTabs()
        let host = HostedWindow(tabs.view)
        defer { host.close() }
        guard await waitUntil({ tabs.appearances.tokens["form"] != nil }, timeout: .seconds(3)) else { return }
        let original = try #require(tabs.appearances.tokens["form"])
        for badge in ["1", "2", "3", "4", nil] as [String?] {
            tabs.setBadge(badge, for: .form)
            tabs.setTabAccessibilityIdentifier(badge.map { "form.\($0)" }, for: .form)
            try await Task.sleep(for: .milliseconds(150))
            #expect(tabs.appearances.tokens["form"] == original)
            #expect(tabs.selectedTabIndex == 0)
#if os(iOS)
            let controller = try #require(host.controller(ofType: UITabBarController.self))
            let item = try #require(controller.tabBar.items?.first)
            guard await waitUntil({
                item.badgeValue == badge && item.accessibilityIdentifier == badge.map { "form.\($0)" }
            }, timeout: .seconds(3)) else { return }
#endif
        }
#if os(iOS)
        // Metadata on a tab that has never appeared must update too.
        tabs.setBadge("new", for: .other)
        tabs.setTabAccessibilityIdentifier("tab.other", for: .other)
        tabs.setTabAccessibilityIdentifier("tab.form", for: .form)
        let controller = try #require(host.controller(ofType: UITabBarController.self))
        guard await waitUntil({ controller.tabBar.items?.last?.accessibilityIdentifier == "tab.other" }) else { return }
        #expect(controller.tabBar.items?.last?.badgeValue == "new")
        #expect(controller.tabBar.items?.first?.accessibilityIdentifier == "tab.form")
        tabs.selectFirstTab(.other)
        try await Task.sleep(for: .milliseconds(150))
        tabs.selectFirstTab(.form)
        try await Task.sleep(for: .milliseconds(150))
        #expect(tabs.appearances.tokens["form"] == original)
#endif
    }

    @Test func seededPathRendersItsDetail() async {
        let flow = HostedFlow(seeded: true)
        let host = HostedWindow(flow.view)
        defer { host.close() }
        _ = await waitUntil({ flow.appearances.tokens["detail"] != nil }, timeout: .seconds(3))
        #expect(flow.depth == 1)
    }

    @Test func modalQueueAdvancesAcrossPresentationStyles() async {
        let flow = HostedFlow()
        let host = HostedWindow(flow.view)
        defer { host.close() }
        guard await waitUntil({ host.isReady && flow.appearances.tokens["home"] != nil }, timeout: .seconds(5)) else { return }
        flow.present(.modal(name: "cover"), as: .fullScreenCover)
        flow.present(.modal(name: "sheet"), as: .sheet)
        guard await waitUntil({ flow.appearances.tokens["cover"] != nil }, timeout: .seconds(3)) else { return }
        #expect(flow.appearances.tokens["sheet"] == nil)
        flow.dismissPresentedModal()
        guard await waitUntil({ flow.appearances.tokens["sheet"] != nil }, timeout: .seconds(3)) else { return }
        #expect(flow.pendingModalCount == 0)
        flow.dismissPresentedModal()
    }

    @Test func pushedTabRootWrapperRendersNestedDetail() async {
        let leaf = HostedFlow()
        let tabs = RevalidationTabs(RevalidationRoot(leaf))
        let outer = HostedFlow()
        outer.route(to: .child(tabs))
        outer.activated()
        leaf.route(to: .detail)
        let host = HostedWindow(outer.view)
        defer { host.close() }
        _ = await waitUntil({ leaf.appearances.tokens["detail"] != nil }, timeout: .seconds(3))
    }

#if os(iOS)
    @Test func pushedWrapperCanBeReusedAsSheet() async throws {
        let leaf = HostedFlow()
        let wrapper = RevalidationRoot(leaf).activated()
        let outer = HostedFlow()
        outer.route(to: .child(wrapper))
        leaf.route(to: .detail)
        let host = HostedWindow(outer.view)
        defer { host.close() }
        guard await waitUntil({ leaf.appearances.tokens["detail"] != nil }, timeout: .seconds(3)) else { return }
        outer.pop()
        try await Task.sleep(for: .milliseconds(350))
        leaf.appearances.tokens.removeValue(forKey: "detail")
        outer.present(.child(wrapper))
        leaf.route(to: .detail)
        guard await waitUntil({ leaf.appearances.tokens["detail"] != nil }, timeout: .seconds(3)) else { return }
        #expect(!leaf.hasLayerNavigationCoordinatable)
        outer.dismissPresentedModal()
    }
#endif
}
#endif
