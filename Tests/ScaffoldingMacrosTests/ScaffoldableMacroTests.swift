import Testing
import SwiftBasicFormat
import SwiftParser
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import ScaffoldingMacros

@Suite("Scaffoldable syntax and diagnostics")
struct ScaffoldableMacroTests {
    private func expand(_ body: String, arguments: String = "", kind: String = "FlowCoordinatable", access: String = "") throws -> (String, [String]) {
        let file = Parser.parse(source: "@Scaffoldable\(arguments) \(access) final class Example: \(kind) {\n\(body)\n}")
        let declaration = try #require(file.statements.first?.item.as(ClassDeclSyntax.self))
        let attribute = try #require(declaration.attributes.first?.as(AttributeSyntax.self))
        let context = BasicMacroExpansionContext()
        let members = try ScaffoldableMacro.expansion(
            of: attribute, providingMembersOf: declaration, conformingTo: [], in: context
        )
        let source = members.map { $0.formatted().description }.joined(separator: "\n")
        #expect(!Parser.parse(source: source).hasError, "Generated declarations must parse: \(source)")
        return (source, context.diagnostics.map(\.message))
    }

    @Test(arguments: [
        "some SwiftUI.View", "any Scaffolding.Coordinatable",
        "(some View,\n some View)", "(any Coordinatable,\n some View)",
        "(some SwiftUI.View, SwiftUI.TabRole)",
        "(any Scaffolding.Coordinatable, some SwiftUI.View, SwiftUI.TabRole)"
    ])
    func recognizesStructuredReturns(_ type: String) throws {
        let (source, diagnostics) = try expand("func screen() -> \(type) { fatalError() }", kind: "Scaffolding.TabCoordinatable")
        #expect(source.contains("case `screen`"))
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: ["() -> (any Coordinatable, TabRole)", "[any Coordinatable]", "Factory<some View>", "ConcreteCoordinator", "Void"])
    func ignoresNonRoutes(_ type: String) throws {
        let (source, diagnostics) = try expand("func helper() -> \(type) { fatalError() }")
        #expect(!source.contains("case `helper`"))
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: [
        "func screen() async -> some View { fatalError() }",
        "func screen() throws -> some View { fatalError() }",
        "func screen<T>(value: T) -> some View { fatalError() }",
        "func screen(value: some View) -> some View { fatalError() }",
        "func screen(value: [some View]) -> some View { fatalError() }",
        "static func screen() -> some View { fatalError() }",
        "func screen(value: inout Int) -> some View { fatalError() }",
        "func screen(value: inout sending String) -> some View { fatalError() }",
        "func screen(values: Int...) -> some View { fatalError() }"
    ])
    func diagnosesUnsupportedRoutes(_ function: String) throws {
        let (_, diagnostics) = try expand(function)
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.contains("Scaffolding route") == true)
    }

    @Test func conditionalClosureAliasesAreEscapingInDefaultFactories() throws {
        let (source, diagnostics) = try expand("""
        #if os(macOS)
        typealias Handler = () -> Int
        #elseif os(iOS)
        typealias Handler = @MainActor () -> Int
        #else
        #if DEBUG
        typealias Handler = (() -> Int)
        #else
        typealias Handler = () -> Int
        #endif
        #endif
        typealias Callback = Handler
        func detail(callback: Callback = { 1 }) -> some View {}
        """)
        #expect(source.contains("@escaping Callback"))
        #expect(source.contains("#elseif os(iOS)"))
        #expect(source.contains("#if DEBUG"))
        #expect(diagnostics.isEmpty)
    }

    @Test func sendingIsRemovedFromStorageButStillCallsTheOriginalFactory() throws {
        let (source, diagnostics) = try expand("func detail(value: sending String = \"default\") -> some View {}")
        #expect(diagnostics.isEmpty)
        #expect(source.contains("case `detail`(`value`: String)"))
        #expect(!source.contains("sending String"))
        #expect(source.contains("instance.`detail`(value: __scaffoldingArgument0)"))
    }

    @Test func nestedSendingFunctionParametersRemainInPayloadTypes() throws {
        let (source, diagnostics) = try expand("func detail(callback: @escaping (sending String) -> Void) -> some View {}")
        #expect(diagnostics.isEmpty)
        #expect(source.contains("(sending String) -> Void"))
    }

    @Test func diagnosesOverloads() throws {
        let (_, diagnostics) = try expand("func screen(id: Int) -> some View {} ; func screen(name: String) -> some View {}")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.contains("unique names") == true)
    }

    @Test func rejectsNonliteralFlags() {
        #expect(throws: (any Error).self) {
            try expand("", arguments: "(injectsCoordinator: 1 == 2)")
        }
    }

    @Test func ignoresQualifiedAttribute() throws {
        let (source, diagnostics) = try expand("@Scaffolding.ScaffoldingIgnored func helper() -> some View {}")
        #expect(!source.contains("case `helper`"))
        #expect(diagnostics.isEmpty)
    }

    @Test func preservesAutoclosureDefaultAndNames() throws {
        let (source, diagnostics) = try expand("func screen(instance: Int, meta: Int, value: @autoclosure () -> Bool = true) -> some View {}")
        #expect(source.contains("__scaffoldingArgument0"))
        #expect(source.contains("__scaffoldingArgument2()"))
        #expect(source.contains("meta: self.meta"))
        #expect(source.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").contains("{ true }"))
        #expect(diagnostics.isEmpty)
    }

    @Test func preservesPackageAccess() throws {
        let (source, diagnostics) = try expand("func home() -> some View {}", arguments: "(injectsCoordinator: false)", access: "package")
        for declaration in ["enum Destinations", "enum Meta", "typealias Owner", "var meta", "var isAvailable", "func value", "nonisolated var _injectsCoordinator"] {
            #expect(source.contains("package " + declaration))
        }
        #expect(diagnostics.isEmpty)
    }

    @Test func preservesMutuallyExclusiveBranches() throws {
        let (source, diagnostics) = try expand("""
        #if os(macOS)
        func screen(id: Int) -> some View {}
        #elseif os(iOS)
        func screen(name: String) -> some View {}
        #else
        #if DEBUG
        func screen() -> some View {}
        #endif
        #endif
        """)
        #expect(source.contains("#elseif os(iOS)"))
        #expect(source.contains("#if DEBUG"))
        #expect(diagnostics.isEmpty)
        let (_, duplicates) = try expand("""
        func screen() -> some View {}
        #if os(macOS)
        func screen(id: Int) -> some View {}
        #endif
        """)
        #expect(duplicates.count == 1)
    }

    @Test func guardsAvailableFactories() throws {
        let (source, diagnostics) = try expand("@available(macOS 27, iOS 27, *) func newer() -> some View {}")
        #expect(source.contains("@available(macOS 27, iOS 27, *)"))
        #expect(source.contains("#available(macOS 27, iOS 27, *)"))
        #expect(source.contains("return false"))
        #expect(diagnostics.isEmpty)
    }

    @Test func payloadAvailabilityGuardsFactoriesWithoutAnnotatingCases() throws {
        let (source, diagnostics) = try expand("@available(macOS 99, *) func newer(id: Int) -> some View {}")
        #expect(source.contains("case `newer`(`id`: Int)"))
        #expect(!source.contains("@available"))
        #expect(source.contains("#available(macOS 99, *)"))
        #expect(diagnostics.isEmpty)
    }

    @Test func defaultsUseIsolatedConvenienceFactories() throws {
        let (source, diagnostics) = try expand("func detail(id: Int = defaultID, title: String = defaultTitle) -> some View {}", access: "public")
        #expect(source.contains("case `detail`(`id`: Int, `title`: String)"))
        #expect(source.components(separatedBy: "public static func `detail`").count == 3)
        #expect(source.contains("@MainActor"))
        #expect(source.contains("__scaffoldingDefault_detail_0()"))
        #expect(source.contains("__scaffoldingDefault_detail_1()"))
        #expect(diagnostics.isEmpty)
    }

    @Test(arguments: ["@available(*, unavailable)", "@available(macOS, obsoleted: 27)", "@available(swift 6.2)"])
    func diagnosesUnsupportedAvailability(_ attribute: String) throws {
        let (_, diagnostics) = try expand("\(attribute) func screen() -> some View {}")
        #expect(diagnostics.count == 1)
        #expect(diagnostics.first?.contains("#if") == true)
    }

    @Test func preservesRouteDocumentationOnCaseAndDefaultFactory() throws {
        let (source, diagnostics) = try expand("""
        // Implementation note that should not become API documentation.
        /// Opens the selected record.
        ///
        /// - Parameter id: The record to edit.
        /// - Returns: An editor for the record.
        @available(macOS 27, *)
        func detail(id: Int = 42) -> some View { Text("Private implementation") }
        """, access: "public")
        let declaration = try #require(Parser.parse(source: source).statements.first?.item.as(EnumDeclSyntax.self))
        let route = try #require(declaration.memberBlock.members.compactMap { $0.decl.as(EnumCaseDeclSyntax.self) }.first)
        let factory = try #require(declaration.memberBlock.members.compactMap { $0.decl.as(FunctionDeclSyntax.self) }.first { $0.name.text == "`detail`" })
        for documentation in [route.leadingTrivia.description, factory.leadingTrivia.description] {
            #expect(documentation.contains("Opens the selected record."))
            #expect(documentation.contains("- Parameter id: The record to edit."))
            #expect(documentation.contains("- Returns: An editor for the record."))
        }
        #expect(!source.contains("Implementation note"))
        #expect(!source.contains("Private implementation"))
        #expect(diagnostics.isEmpty)
    }

    @Test func preservesBlockDocumentationInsideConditionalRoutes() throws {
        let (source, diagnostics) = try expand("""
        #if os(macOS)
        /**
         Opens the library.

         Use this route to start browsing.
         */
        func library() -> some View { EmptyView() }
        #endif
        """)
        #expect(source.contains("Opens the library."))
        #expect(source.contains("Use this route to start browsing."))
        #expect(source.contains("#if os(macOS)"))
        #expect(diagnostics.isEmpty)
    }

    @Test func undocumentedRoutesDoNotPublishImplementationBodies() throws {
        let (source, _) = try expand("func home() -> some View { Text(\"Implementation detail\") }")
        #expect(source.contains("case `home`"))
        #expect(!source.contains("Implementation detail"))
        #expect(!source.contains("///"))
    }
}
