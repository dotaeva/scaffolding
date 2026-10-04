//
//  ScaffoldableMacro.swift
//  Scaffolding
//
//  Created by Alexandr Valíček on 26.09.2025.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftDiagnostics
import Foundation

public struct ScaffoldableMacro: MemberMacro {

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDecl = declaration.as(ClassDeclSyntax.self) else {
            throw ScaffoldingMacroError.onlyApplicableToClass
        }

        let className = classDecl.name.trimmedDescription
        let coordinatableType = try determineCoordinatableType(from: classDecl)
        let modifiers = Set(classDecl.modifiers.map { $0.name.text })
        let accessModifier = !modifiers.isDisjoint(with: ["public", "open"]) ? "public "
            : modifiers.contains("package") ? "package " : ""
        let injectsCoordinator = try parseBoolArgument(named: "injectsCoordinator", from: node)
        let codable = try parseBoolArgument(named: "codable", from: node) ?? false

        let functions = extractFunctions(from: classDecl)
        let trackedFunctions = try filterTrackedFunctions(
            functions, coordinatableType: coordinatableType,
            typeContext: RouteTypeContext(classDecl), context: context
        )

        let destinationsEnum = try generateDestinationsEnum(
            className: className,
            functions: trackedFunctions,
            accessModifier: accessModifier,
            codable: codable
        )

        var members: [DeclSyntax] = [DeclSyntax(destinationsEnum)]

        // Resolve payload names in the owner's scope, before Destinations'
        // own Meta and Owner declarations can shadow the caller's types.
        let aliases = trackedFunctions.flatMap { function in
            function.parameters.compactMap { parameter in
                parameter.scopedAlias.map {
                    var declaration = "\(accessModifier)typealias \($0) = \(parameter.originalType)"
                    if let value = parameter.defaultValue, parameter.scopedDefaultProvider != nil {
                        let visibility = accessModifier == "public " ? "@usableFromInline " : ""
                        declaration += """

                        \(function.availabilityAttributes)\(visibility)@MainActor
                        internal static func __default_\($0)() -> \($0) {
                            \(value)
                        }
                        """
                    }
                    return function.wrapping(declaration)
                }
            }
        }
        if !aliases.isEmpty {
            members.append(DeclSyntax(stringLiteral: """
                \(accessModifier)enum __ScaffoldingRouteTypes {
                    \(aliases.joined(separator: "\n"))
                }
                """))
        }

        // Emit the env-injection opt-out flag when explicitly disabled.
        // The default true value is provided by Coordinatable's protocol
        // extension; only the opt-out needs to be materialised.
        if injectsCoordinator == false {
            members.append(DeclSyntax(stringLiteral: """
                \(accessModifier)nonisolated var _injectsCoordinator: Bool { false }
                """))
        }

        return members
    }

    private static func parseBoolArgument(named name: String, from node: AttributeSyntax) throws -> Bool? {
        guard case let .argumentList(arguments) = node.arguments else { return nil }
        for argument in arguments {
            guard let label = argument.label?.text, label == name else { continue }
            guard let literal = argument.expression.as(BooleanLiteralExprSyntax.self) else {
                throw ScaffoldingMacroError.booleanLiteralRequired(name)
            }
            return literal.literal.tokenKind == .keyword(.true)

        }
        return nil
    }
    
    
    private static func determineCoordinatableType(from classDecl: ClassDeclSyntax) throws -> CoordinatableType {
        if let type = coordinatableTypeFromInheritance(classDecl) {
            return type
        }
        // The conformance may be spelled through a refining protocol
        // (`protocol TabFlow: FlowCoordinatable`), which a macro cannot
        // resolve — it only sees syntax. Fall back to the state container the
        // coordinator is required to declare, which names the kind exactly.
        if let type = coordinatableTypeFromStateContainer(classDecl) {
            return type
        }
        throw ScaffoldingMacroError.mustConformToCoordinatable
    }

    private static func coordinatableTypeFromInheritance(_ classDecl: ClassDeclSyntax) -> CoordinatableType? {
        let inheritanceTypes = classDecl.inheritanceClause?.inheritedTypes.compactMap {
            typeBaseName($0.type)
        } ?? []

        if inheritanceTypes.contains("TabCoordinatable") {
            return .tab
        } else if inheritanceTypes.contains("RootCoordinatable") {
            return .root
        } else if inheritanceTypes.contains("FlowCoordinatable") {
            return .flow
        } else if inheritanceTypes.contains("SplitCoordinatable") {
            return .split
        }
        return nil
    }

    /// Infers the kind from the declared state container — `FlowStack`,
    /// `TabItems`, or `Root` — in either spelling:
    ///
    /// ```swift
    /// var stack = FlowStack<HomeCoordinator>(root: .home)   // initializer
    /// var stack: FlowStack<HomeCoordinator>                 // annotation
    /// ```
    private static func coordinatableTypeFromStateContainer(_ classDecl: ClassDeclSyntax) -> CoordinatableType? {
        for member in classDecl.memberBlock.members {
            guard let variable = member.decl.as(VariableDeclSyntax.self) else { continue }

            for binding in variable.bindings {
                if let annotation = binding.typeAnnotation?.type,
                   let name = typeBaseName(annotation),
                   let type = CoordinatableType(stateContainerName: name) {
                    return type
                }
                if let call = binding.initializer?.value.as(FunctionCallExprSyntax.self),
                   let name = calleeBaseName(of: call),
                   let type = CoordinatableType(stateContainerName: name) {
                    return type
                }
            }
        }
        return nil
    }

    /// `FlowStack<X>(root:)` → `FlowStack`; also handles the unspecialized form.
    private static func calleeBaseName(of call: FunctionCallExprSyntax) -> String? {
        var expression = call.calledExpression
        if let generic = expression.as(GenericSpecializationExprSyntax.self) {
            expression = generic.expression
        }
        if let reference = expression.as(DeclReferenceExprSyntax.self) { return reference.baseName.text }
        return expression.as(MemberAccessExprSyntax.self)?.declName.baseName.text
    }

    private static func typeBaseName(_ type: TypeSyntax) -> String? {
        if let attributed = type.as(AttributedTypeSyntax.self) { return typeBaseName(attributed.baseType) }
        if let identifier = type.as(IdentifierTypeSyntax.self) { return identifier.name.text }
        return type.as(MemberTypeSyntax.self)?.name.text
    }

    private static func extractFunctions(from classDecl: ClassDeclSyntax) -> [ConditionalFunction] {
        func collect(_ members: MemberBlockItemListSyntax, branches: [ConditionalBranch]) -> [ConditionalFunction] {
            members.flatMap { member -> [ConditionalFunction] in
                if let function = member.decl.as(FunctionDeclSyntax.self) {
                    return [ConditionalFunction(function: function, branches: branches)]
                }
                guard let conditional = member.decl.as(IfConfigDeclSyntax.self) else { return [] }
                var directives: [String] = []
                var functions: [ConditionalFunction] = []
                for (index, clause) in conditional.clauses.enumerated() {
                    directives.append(clause.poundKeyword.text + (clause.condition.map { " " + $0.trimmedDescription } ?? ""))
                    if case let .decls(members) = clause.elements {
                        functions += collect(members, branches: branches + [ConditionalBranch(
                            id: conditional.id, index: index, directives: directives
                        )])
                    }
                }
                return functions
            }
        }
        return collect(classDecl.memberBlock.members, branches: [])
    }

    private static func filterTrackedFunctions(
        _ functions: [ConditionalFunction],
        coordinatableType: CoordinatableType,
        typeContext: RouteTypeContext,
        context: some MacroExpansionContext
    ) throws -> [TrackedFunction] {
        var trackedFunctions: [TrackedFunction] = []

        
        for conditional in functions {
            let function = conditional.function
            let hasScaffoldingIgnored = hasAttribute(function, named: "ScaffoldingIgnored")
            
            if hasScaffoldingIgnored {
                continue
            }
            
            let returnTypeInfo = try parseReturnType(function.signature.returnClause?.type)
            let shouldAutoTrack = shouldAutoTrackFunction(returnType: returnTypeInfo)
            
            if shouldAutoTrack {
                if let problem = unsupportedSignature(function) {
                    context.diagnose(Diagnostic(node: function, message: ScaffoldingMacroWarning(message: problem, severity: .error)))
                    continue
                }
                guard !trackedFunctions.contains(where: {
                    $0.originalFunction.name.text == function.name.text && !$0.isExclusive(with: conditional.branches)
                }) else {
                    context.diagnose(Diagnostic(node: function.name, message: ScaffoldingMacroWarning(
                        message: "Scaffolding routes must have unique names; rename this overload or mark it @ScaffoldingIgnored.", severity: .error
                    )))
                    continue
                }
                // Warn about tuple types in non-TabCoordinatable
                if coordinatableType != .tab && returnTypeInfo.isTupleType {
                    context.diagnose(Diagnostic(
                        node: function,
                        message: ScaffoldingMacroWarning.tupleIgnoredInNonTabCoordinatable
                    ))
                }
                
                // Warn about TabRole in non-TabCoordinatable
                if coordinatableType != .tab && returnTypeInfo.hasTabRole {
                    context.diagnose(Diagnostic(
                        node: function,
                        message: ScaffoldingMacroWarning.tabRoleIgnoredInNonTabCoordinatable
                    ))
                }
                
                for branches in typeContext.branches(for: conditional) {
                    trackedFunctions.append(try TrackedFunction(
                        function: function,
                        returnType: returnTypeInfo,
                        branches: branches,
                        typeContext: typeContext
                    ))
                }
            }
        }
        
        return trackedFunctions
    }
    
    private static func hasAttribute(_ function: FunctionDeclSyntax, named attributeName: String) -> Bool {
        function.attributes.contains {
            guard let attribute = $0.as(AttributeSyntax.self) else { return false }
            return typeBaseName(attribute.attributeName) == attributeName
        }
    }

    private static func containsOpaqueType(_ syntax: Syntax) -> Bool {
        if let type = syntax.as(SomeOrAnyTypeSyntax.self), type.someOrAnySpecifier.text == "some" { return true }
        return syntax.children(viewMode: .sourceAccurate).contains(where: containsOpaqueType)
    }

    private static func unsupportedSignature(_ function: FunctionDeclSyntax) -> String? {
        if function.genericParameterClause != nil || function.genericWhereClause != nil ||
            function.signature.parameterClause.parameters.contains(where: {
                containsOpaqueType(Syntax($0.type))
            }) {
            return "Scaffolding routes cannot be generic; use a concrete parameter type or mark the helper @ScaffoldingIgnored."
        }
        if function.signature.effectSpecifiers != nil {
            return "Scaffolding route factories must be synchronous and nonthrowing; perform async or throwing work before routing."
        }
        if function.modifiers.contains(where: { ["static", "class"].contains($0.name.text) }) {
            return "Scaffolding route factories must be instance methods."
        }
        for attribute in function.attributes.compactMap({ $0.as(AttributeSyntax.self) }) where typeBaseName(attribute.attributeName) == "available" {
            if case let .availability(arguments) = attribute.arguments {
                for item in arguments {
                    switch item.argument {
                    case .token(let token) where token.text == "unavailable":
                        return "Scaffolding routes cannot be unavailable; conditionally compile the route with #if instead."
                    case .availabilityLabeledArgument(let argument) where argument.label.text == "obsoleted":
                        return "Scaffolding routes cannot use obsoleted availability; conditionally compile the route with #if instead."
                    case .availabilityVersionRestriction(let version) where version.platform.text == "swift":
                        return "Scaffolding routes must use #if swift(...) for language-version availability."
                    default: break
                    }
                }
            }
        }
        for parameter in function.signature.parameterClause.parameters {
            let unsupported = parameter.type.as(AttributedTypeSyntax.self)?.specifiers.contains {
                ["inout", "borrowing", "consuming", "isolated"].contains($0.trimmedDescription)
            } ?? false
            if parameter.ellipsis != nil || unsupported {
                return "Scaffolding route parameters must be stored values; inout, ownership modifiers, isolated parameters, and variadics are unsupported."
            }
        }
        return nil
    }

    /// Match syntax nodes, never substrings: closures, arrays and unrelated
    /// generic types may contain these words without being destinations.
    private static func parseReturnType(_ type: TypeSyntax?) throws -> ReturnTypeInfo {
        guard let type else { return .void }
        enum Component { case view, coordinator, role, other }
        func component(_ type: TypeSyntax) -> Component {
            if let opaque = type.as(SomeOrAnyTypeSyntax.self) {
                let name = typeBaseName(opaque.constraint)
                if opaque.someOrAnySpecifier.tokenKind == .keyword(.some), name == "View" { return .view }
                if opaque.someOrAnySpecifier.tokenKind == .keyword(.any), name == "Coordinatable" { return .coordinator }
            }
            if typeBaseName(type) == "TabRole" { return .role }
            return .other
        }
        if let tuple = type.as(TupleTypeSyntax.self) {
            switch tuple.elements.map({ component($0.type) }) {
            case [.coordinator, .view]: return .coordinatableViewTuple
            case [.view, .view]: return .viewViewTuple
            case [.coordinator, .role]: return .coordinatableTabRoleTuple
            case [.view, .role]: return .viewTabRoleTuple
            case [.coordinator, .view, .role]: return .coordinatableViewTabRoleTuple
            case [.view, .view, .role]: return .viewViewTabRoleTuple
            default: return .other
            }
        }
        switch component(type) {
        case .view: return .someView
        case .coordinator: return .anyCoordinatable
        default: return .other
        }
    }

    private static func shouldAutoTrackFunction(returnType: ReturnTypeInfo) -> Bool {
        switch returnType {
        case .someView, .anyCoordinatable,
             .coordinatableViewTuple, .viewViewTuple,
             .viewTabRoleTuple, .coordinatableTabRoleTuple,
             .viewViewTabRoleTuple, .coordinatableViewTabRoleTuple:
            return true
        case .void, .other:
            return false
        }
    }
    
    private static func generateDestinationsEnum(
        className: String,
        functions: [TrackedFunction],
        accessModifier: String,
        codable: Bool = false
    ) throws -> EnumDeclSyntax {
        let metaCases = functions.map { $0.wrapping("case \($0.name)") }.joined(separator: "\n")
        let mainCases = try functions.map {
            // Swift forbids introduction availability on payload-bearing cases.
            // Their payloads must exist at the coordinator's deployment floor;
            // isAvailable and value(for:) still guard the route factory.
            let availability = $0.parameters.isEmpty ? $0.availabilityAttributes : ""
            return $0.wrapping(generateDocumentationTrivia(for: $0).description + availability + (try generateEnumCaseDecl(for: $0)).description)
        }.joined(separator: "\n")
        let defaultFactories = functions.map {
            generateDefaultFactories(for: $0, accessModifier: accessModifier)
        }.joined(separator: "\n")
        let metaSwitch = functions.map {
            $0.wrapping("case .\($0.name): return .\($0.name)")
        }.joined(separator: "\n")
        let availabilitySwitch = functions.map { function in
            function.wrapping("case .\(function.name): " + function.checkingAvailability(
                "return true", fallback: "return false"
            ))
        }.joined(separator: "\n")
        let valueSwitch = functions.map { function in
            let pattern = "case .\(function.name)\(generateParameterExtraction(for: function)): "
            let call = generateDestinationInit(for: function, functionCall: generateFunctionCall(for: function))
            return function.wrapping(pattern + function.checkingAvailability(
                "return \(call)", fallback: "preconditionFailure(\"This Scaffolding route is unavailable on this OS. Check isAvailable before routing.\")"
            ))
        }.joined(separator: "\n")
        let conformances = codable ? "Destinationable, Codable" : "Destinationable"
        return try EnumDeclSyntax("""
        \(raw: accessModifier)enum Destinations: \(raw: conformances) {
            \(raw: accessModifier)typealias Owner = \(raw: className)
            \(raw: accessModifier)enum Meta: DestinationMeta {
                \(raw: metaCases)
            }
            \(raw: mainCases)
            \(raw: defaultFactories)
            \(raw: accessModifier)var meta: Meta {
                switch self {
                    \(raw: metaSwitch)
                }
            }
            \(raw: accessModifier)var isAvailable: Bool {
                switch self {
                    \(raw: availabilitySwitch)
                }
            }
            \(raw: accessModifier)func value(for instance: Owner) -> Destination {
                switch self {
                    \(raw: valueSwitch)
                }
            }
        }
        """)
    }

    private static func generateEnumCaseDecl(for function: TrackedFunction) throws -> EnumCaseDeclSyntax {
        if function.parameters.isEmpty {
            let enumCaseDecl = EnumCaseDeclSyntax {
                EnumCaseElementSyntax(name: .identifier(function.name))
            }
            
            return enumCaseDecl
        } else {
            let params = function.parameters.enumerated().map { (index, param) in
                let isLast = index == function.parameters.count - 1
                
                if let label = param.label {
                    return EnumCaseParameterSyntax(
                        firstName: .identifier(label),
                        colon: .colonToken(),
                        type: IdentifierTypeSyntax(name: .identifier(param.type)),
                        trailingComma: isLast ? nil : .commaToken()
                    )
                } else {
                    return EnumCaseParameterSyntax(
                        type: IdentifierTypeSyntax(name: .identifier(param.type)),
                        trailingComma: isLast ? nil : .commaToken()
                    )
                }
            }
            
            let enumCaseDecl = EnumCaseDeclSyntax {
                EnumCaseElementSyntax(
                    name: .identifier(function.name),
                    parameterClause: EnumCaseParameterClauseSyntax(
                        parameters: EnumCaseParameterListSyntax(params)
                    )
                )
            }
            
            return enumCaseDecl
        }
    }

    /// Enum-case constructors are nonisolated, even in a main-actor enum.
    /// Keep stored cases free of defaults and evaluate defaults in isolated
    /// convenience factories instead. A renamed label makes each factory
    /// applicable only when that original argument is omitted. Keeping the
    /// expression in a default argument also preserves #fileID/#line semantics.
    private static func generateDefaultFactories(for function: TrackedFunction, accessModifier: String) -> String {
        let parameters = function.parameters
        let defaults = parameters.indices.filter { parameters[$0].defaultValue != nil }
        guard !defaults.isEmpty else { return "" }

        var defaultValues = parameters.map { parameter in
            parameter.scopedDefaultProvider.map { "\($0)()" } ?? parameter.defaultValue
        }
        var providers: [String] = []
        if accessModifier == "public " {
            // Public defaults are serialized into clients and cannot directly
            // mention an owner's private state. An ABI-visible internal helper
            // keeps that expression in the defining module. Bare source-location
            // literals must stay directly in the caller's default argument.
            for index in defaults {
                if parameters[index].scopedDefaultProvider != nil { continue }
                let expression = defaultValues[index]!
                if Parameter.sourceLocationLiterals.contains(expression) { continue }
                let name = "__scaffoldingDefault_\(function.name.replacingOccurrences(of: "`", with: ""))_\(index)"
                defaultValues[index] = "\(name)()"
                providers.append(function.wrapping("""
                \(function.availabilityAttributes)@usableFromInline @MainActor
                internal static func \(name)() -> \(parameters[index].type) {
                    \(expression)
                }
                """))
            }
        }

        var omissions: [Set<Int>] = []
        let needsExplicitOmissions = defaults.contains {
            parameters[$0].label == nil || parameters[$0].isSourceLocationAutoclosure
        }
        if needsExplicitOmissions {
            // Explicit overloads preserve Swift's left-to-right matching of
            // unlabeled arguments. Deduplicate equivalent visible signatures,
            // preferring to supply earlier parameters and omit later ones.
            // Source-location autoclosures also need separate omissions: an
            // omitted argument keeps its literal default, while a supplied
            // argument remains a stored closure like the enum-case payload.
            func collect(_ offset: Int, omitted: Set<Int>) {
                guard offset < defaults.count else {
                    if !omitted.isEmpty { omissions.append(omitted) }
                    return
                }
                collect(offset + 1, omitted: omitted)
                collect(offset + 1, omitted: omitted.union([defaults[offset]]))
            }
            collect(0, omitted: [])
        } else {
            // The first omitted label determines the overload. Later defaults
            // stay optional, requiring only one factory per defaulted argument.
            omissions = defaults.map { [$0] }
        }

        let labels = Set(parameters.compactMap(\.label).map { $0.replacingOccurrences(of: "`", with: "") })
        var signatures = Set<String>()
        let factories = omissions.compactMap { omitted -> String? in
            let signature = parameters.indices.filter { !omitted.contains($0) }.map {
                "\(parameters[$0].label ?? "_"):\(parameters[$0].type)"
            }.joined(separator: ",")
            guard signatures.insert(signature).inserted else { return nil }
            let firstOmitted = omitted.min()!
            let arguments = parameters.enumerated().map { index, parameter in
                var label = parameter.label ?? "_"
                if omitted.contains(index) {
                    label = "__scaffoldingDefault\(index)"
                    while labels.contains(label) { label += "_" }
                }
                let usesDefault = omitted.contains(index) || (!needsExplicitOmissions && index > firstOmitted)
                let value = usesDefault ? defaultValues[index].map { " = \($0)" } ?? "" : ""
                let autoclosure = omitted.contains(index) && parameter.isSourceLocationAutoclosure
                    ? "@autoclosure " : ""
                let type = autoclosure + (parameter.isFunction ? "@escaping " : "") + parameter.type
                return "\(label) __scaffoldingArgument\(index): \(type)\(value)"
            }.joined(separator: ", ")
            let values = parameters.enumerated().map { index, parameter in
                (parameter.label.map { $0.replacingOccurrences(of: "`", with: "") + ": " } ?? "") + "__scaffoldingArgument\(index)"
            }.joined(separator: ", ")
            return function.wrapping("""
            \(generateDocumentationTrivia(for: function))\(function.availabilityAttributes)@MainActor
            \(accessModifier)static func \(function.name)(\(arguments)) -> Self {
                .\(function.name)(\(values))
            }
            """)
        }
        return (providers + factories).joined(separator: "\n")
    }
    
    /// Keep the author's DocC prose on both the case and its default factories.
    /// Ordinary implementation comments and function bodies are not API docs.
    private static func generateDocumentationTrivia(for function: TrackedFunction) -> Trivia {
        var pieces: [TriviaPiece] = []
        for piece in function.originalFunction.leadingTrivia {
            switch piece {
            case .docLineComment, .docBlockComment:
                pieces.append(piece)
                pieces.append(.newlines(1))
            default:
                break
            }
        }
        return Trivia(pieces: pieces)
    }

    private static func generateParameterExtraction(for function: TrackedFunction) -> String {
        if function.parameters.isEmpty {
            return ""
        }
        
        let params = function.parameters.indices.map { index in
            return "let __scaffoldingArgument\(index)"
        }.joined(separator: ", ")
        
        return "(\(params))"
    }
    
    private static func generateFunctionCall(for function: TrackedFunction) -> String {
        if function.parameters.isEmpty {
            return "instance.\(function.name)()"
        }
        
        let params = function.parameters.enumerated().map { index, param in
            let value = "__scaffoldingArgument\(index)" + (param.isAutoclosure ? "()" : "")
            if let label = param.label {
                return "\(label.replacingOccurrences(of: "`", with: "")): \(value)"
            } else {
                return value
            }
        }.joined(separator: ", ")
        
        return "instance.\(function.name)(\(params))"
    }
    
    private static func generateDestinationInit(for function: TrackedFunction, functionCall: String) -> String {
        switch function.returnType {
        case .someView:
            return ".init(\(functionCall), meta: self.meta, parent: instance)"
        case .anyCoordinatable:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .coordinatableViewTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .viewViewTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .viewTabRoleTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .coordinatableTabRoleTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .viewViewTabRoleTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .coordinatableViewTabRoleTuple:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        case .void, .other:
            return ".init({ [unowned instance] in \(functionCall) }, meta: self.meta, parent: instance)"
        }
    }
}

// MARK: - Supporting Types

enum CoordinatableType {
    case flow, tab, root, split

    /// Maps a state-container type name to the coordinator kind that owns it.
    init?(stateContainerName: String) {
        switch stateContainerName {
        case "FlowStack": self = .flow
        case "TabItems": self = .tab
        case "Root": self = .root
        case "SplitColumns": self = .split
        default: return nil
        }
    }
}

enum ReturnTypeInfo {
    case void
    case someView
    case anyCoordinatable
    case coordinatableViewTuple      // (any Coordinatable, some View)
    case viewViewTuple               // (some View, some View)
    case viewTabRoleTuple            // (some View, TabRole)
    case coordinatableTabRoleTuple   // (any Coordinatable, TabRole)
    case viewViewTabRoleTuple        // (some View, some View, TabRole)
    case coordinatableViewTabRoleTuple // (any Coordinatable, some View, TabRole)
    case other
    
    var isTupleType: Bool {
        switch self {
        case .coordinatableViewTuple, .viewViewTuple,
             .viewTabRoleTuple, .coordinatableTabRoleTuple,
             .viewViewTabRoleTuple, .coordinatableViewTabRoleTuple:
            return true
        default:
            return false
        }
    }
    
    var hasTabRole: Bool {
        switch self {
        case .viewTabRoleTuple, .coordinatableTabRoleTuple,
             .viewViewTabRoleTuple, .coordinatableViewTabRoleTuple:
            return true
        default:
            return false
        }
    }
}

struct TrackedFunction {
    let name: String
    let parameters: [Parameter]
    let returnType: ReturnTypeInfo
    let originalFunction: FunctionDeclSyntax
    let branches: [ConditionalBranch]
    
    init(function: FunctionDeclSyntax, returnType: ReturnTypeInfo, branches: [ConditionalBranch], typeContext: RouteTypeContext) throws {
        self.branches = branches
        self.name = "`" + function.name.text.replacingOccurrences(of: "`", with: "") + "`"
        self.returnType = returnType
        self.originalFunction = function
        self.parameters = try function.signature.parameterClause.parameters.enumerated().map { index, param in
            try Parameter(from: param, typeContext: typeContext, branches: branches, alias: "\(function.name.text.replacingOccurrences(of: "`", with: ""))_\(index)")
        }
    }
}

struct ConditionalBranch {
    let id: SyntaxIdentifier
    let index: Int
    let directives: [String]
}

struct ConditionalFunction {
    let function: FunctionDeclSyntax
    let branches: [ConditionalBranch]
}

extension TrackedFunction {
    func isExclusive(with other: [ConditionalBranch]) -> Bool {
        branches.contains { branch in other.contains { $0.id == branch.id && $0.index != branch.index } }
    }

    func wrapping(_ source: String) -> String {
        branches.reversed().reduce(source) { body, branch in
            branch.directives.joined(separator: "\n") + "\n" + body + "\n#endif"
        }
    }

    private var availability: [AttributeSyntax] {
        originalFunction.attributes.compactMap { $0.as(AttributeSyntax.self) }
            .filter { $0.attributeName.trimmedDescription == "available" }
    }

    var availabilityAttributes: String {
        availability.map { $0.trimmedDescription + "\n" }.joined()
    }

    func checkingAvailability(_ body: String, fallback: String) -> String {
        let conditions = availability.compactMap { attribute -> String? in
            guard case let .availability(arguments) = attribute.arguments else { return nil }
            var restrictions: [String] = []
            var platform: String?
            for item in arguments {
                switch item.argument {
                case .availabilityVersionRestriction(let version): restrictions.append(version.trimmedDescription)
                case .token(let token):
                    if token.text != "*" { platform = token.text }
                case .availabilityLabeledArgument(let argument):
                    if argument.label.text == "introduced", let platform {
                        restrictions.append(platform + " " + argument.value.trimmedDescription)
                    }
                }
            }
            return restrictions.isEmpty ? nil : restrictions.joined(separator: ", ") + ", *"
        }
        return conditions.reversed().reduce(body) { result, condition in
            "if #available(" + condition + ") { " + result + " } else { " + fallback + " }"
        }
    }
}

/// The syntax visible to the member macro. Alias lookup deliberately stops at
/// the class boundary; aliases from other scopes can be marked @escaping at
/// the route declaration, just as with imported closure aliases.
struct RouteTypeContext {
    let className: String
    private struct Alias {
        let type: TypeSyntax
        let branches: [ConditionalBranch]
    }
    private let aliases: [String: [Alias]]
    private let branchOptions: [SyntaxIdentifier: [ConditionalBranch]]

    init(_ declaration: ClassDeclSyntax) {
        className = declaration.name.trimmedDescription
        var aliases: [String: [Alias]] = [:]
        var branchOptions: [SyntaxIdentifier: [ConditionalBranch]] = [:]
        func collect(_ members: MemberBlockItemListSyntax, branches: [ConditionalBranch]) {
            for member in members {
                if let alias = member.decl.as(TypeAliasDeclSyntax.self) {
                    aliases[alias.name.text, default: []].append(Alias(type: alias.initializer.value, branches: branches))
                } else if let conditional = member.decl.as(IfConfigDeclSyntax.self) {
                    var directives: [String] = []
                    for (index, clause) in conditional.clauses.enumerated() {
                        directives.append(clause.poundKeyword.text + (clause.condition.map { " " + $0.trimmedDescription } ?? ""))
                        let branch = ConditionalBranch(id: conditional.id, index: index, directives: directives)
                        branchOptions[conditional.id, default: []].append(branch)
                        if case let .decls(members) = clause.elements {
                            collect(members, branches: branches + [branch])
                        }
                    }
                    // Without a local alias in this branch, Swift may resolve
                    // the name in an outer scope. Do not drop the route there.
                    if conditional.clauses.last?.poundKeyword.text != "#else" {
                        branchOptions[conditional.id, default: []].append(ConditionalBranch(
                            id: conditional.id, index: conditional.clauses.count,
                            directives: directives + ["#else"]
                        ))
                    }
                }
            }
        }
        collect(declaration.memberBlock.members, branches: [])
        self.aliases = aliases
        self.branchOptions = branchOptions
    }

    /// A default factory may need @escaping on one platform and a value
    /// parameter on another. Keep those declarations under the alias's actual
    /// branches instead of selecting whichever alias appears first in source.
    func branches(for function: ConditionalFunction) -> [[ConditionalBranch]] {
        function.function.signature.parameterClause.parameters.reduce([function.branches]) { variants, parameter in
            variants.flatMap { functionTypes(parameter.type, branches: $0).map(\.branches) }
        }
    }

    func isFunction(_ type: TypeSyntax, branches: [ConditionalBranch]) -> Bool {
        functionTypes(type, branches: branches).first?.isFunction ?? false
    }

    private func functionTypes(_ type: TypeSyntax, branches: [ConditionalBranch], visited: Set<String> = []) -> [(branches: [ConditionalBranch], isFunction: Bool)] {
        if type.is(FunctionTypeSyntax.self) { return [(branches, true)] }
        if let attributed = type.as(AttributedTypeSyntax.self) {
            return functionTypes(attributed.baseType, branches: branches, visited: visited)
        }
        if let tuple = type.as(TupleTypeSyntax.self), tuple.elements.count == 1,
           let element = tuple.elements.first, element.firstName == nil {
            return functionTypes(element.type, branches: branches, visited: visited)
        }
        let name: String?
        if let identifier = type.as(IdentifierTypeSyntax.self) {
            name = identifier.name.text
        } else if let member = type.as(MemberTypeSyntax.self),
                  [className, "Self"].contains(member.baseType.trimmedDescription) {
            name = member.name.text
        } else {
            name = nil
        }
        guard let name, !visited.contains(name), let candidates = aliases[name] else { return [(branches, false)] }
        let compatible = candidates.filter { alias in
            !alias.branches.contains(where: { branch in
                branches.contains { $0.id == branch.id && $0.index != branch.index }
            })
        }
        if let unresolved = compatible.flatMap(\.branches).first(where: { branch in
            !branches.contains { $0.id == branch.id }
        }), let options = branchOptions[unresolved.id] {
            return options.flatMap { functionTypes(type, branches: branches + [$0], visited: visited) }
        }
        guard let alias = compatible.first else { return [(branches, false)] }
        return functionTypes(alias.type, branches: branches, visited: visited.union([name]))
    }

    func needsScopedAlias(_ syntax: Syntax) -> Bool {
        if let identifier = syntax.as(IdentifierTypeSyntax.self),
           ["Meta", "Owner"].contains(identifier.name.text) { return true }
        if let reference = syntax.as(DeclReferenceExprSyntax.self),
           ["Meta", "Owner"].contains(reference.baseName.text) { return true }
        return syntax.children(viewMode: .sourceAccurate).contains(where: needsScopedAlias)
    }
}

struct Parameter {
    static let sourceLocationLiterals: Set<String> = ["#file", "#fileID", "#filePath", "#function", "#line", "#column"]

    let label: String?
    let type: String
    let originalType: String
    let scopedAlias: String?
    let defaultValue: String?
    let isAutoclosure: Bool
    let isFunction: Bool
    let isSourceLocationAutoclosure: Bool

    var scopedDefaultProvider: String? {
        guard let scopedAlias, let defaultValue,
              !Self.sourceLocationLiterals.contains(defaultValue) else { return nil }
        return String(type.dropLast(scopedAlias.count)) + "__default_" + scopedAlias
    }
    
    init(from param: FunctionParameterSyntax, typeContext: RouteTypeContext, branches: [ConditionalBranch], alias: String) throws {
        // Handle parameter labels
        if param.firstName.text != "_" {
            self.label = "`" + param.firstName.text.replacingOccurrences(of: "`", with: "") + "`"
        } else {
            self.label = nil
        }
        
        var storedType = param.type
        var hasEscapingAttribute = false
        if var attributed = storedType.as(AttributedTypeSyntax.self) {
            // `sending` constrains the factory call, not the stored payload.
            // Keep it on the user's method so Swift still checks the transfer
            // when the generated bridge calls that method. Nested function
            // parameter/result annotations remain part of the payload type.
            attributed.specifiers = attributed.specifiers.filter { $0.trimmedDescription != "sending" }
            self.isAutoclosure = attributed.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "autoclosure"
            }
            hasEscapingAttribute = attributed.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "escaping"
            }
            attributed.attributes = attributed.attributes.filter {
                guard let attribute = $0.as(AttributeSyntax.self) else { return true }
                return !["escaping", "autoclosure"].contains(attribute.attributeName.trimmedDescription)
            }
            storedType = TypeSyntax(attributed)
        } else {
            self.isAutoclosure = false
        }
        self.originalType = storedType.trimmedDescription
        let hasShadowedDefault = param.defaultValue.map { typeContext.needsScopedAlias(Syntax($0.value)) } == true
        self.scopedAlias = typeContext.needsScopedAlias(Syntax(storedType)) || hasShadowedDefault ? alias : nil
        self.type = scopedAlias.map { "\(typeContext.className).__ScaffoldingRouteTypes.\($0)" } ?? originalType
        self.isFunction = hasEscapingAttribute || isAutoclosure || typeContext.isFunction(storedType, branches: branches)
        self.isSourceLocationAutoclosure = isAutoclosure &&
            param.defaultValue.map { Self.sourceLocationLiterals.contains($0.value.trimmedDescription) } == true
        if let value = param.defaultValue?.value.trimmedDescription {
            self.defaultValue = isAutoclosure && !isSourceLocationAutoclosure ? "{ \(value) }" : value
        } else {
            self.defaultValue = nil
        }
    }

}

// MARK: - Errors and Warnings

enum ScaffoldingMacroError: Error, CustomStringConvertible {
    case onlyApplicableToClass
    case mustConformToCoordinatable
    case booleanLiteralRequired(String)
    case invalidParameter
    case codeGenerationFailed
    
    var description: String {
        switch self {
        case .onlyApplicableToClass:
            return "@Scaffoldable can only be applied to classes"
        case .mustConformToCoordinatable:
            return "@Scaffoldable can only be applied to classes that conform to FlowCoordinatable, TabCoordinatable, RootCoordinatable, or SplitCoordinatable"
        case .booleanLiteralRequired(let name):
            return "@Scaffoldable requires a literal true or false for \(name)."
        case .invalidParameter:
            return "Invalid function parameter"
        case .codeGenerationFailed:
            return "Failed to generate extension code"
        }
    }
}

struct ScaffoldingMacroWarning: DiagnosticMessage {
    static let tupleIgnoredInNonTabCoordinatable = ScaffoldingMacroWarning(
        message: "Second view in tuple return type will be ignored in non-TabCoordinatable classes",
        severity: .warning
    )
    
    static let tabRoleIgnoredInNonTabCoordinatable = ScaffoldingMacroWarning(
        message: "TabRole will be ignored in non-TabCoordinatable classes",
        severity: .warning
    )
    
    let message: String
    let diagnosticID: MessageID
    let severity: DiagnosticSeverity
    
    init(message: String, severity: DiagnosticSeverity) {
        self.message = message
        self.severity = severity
        self.diagnosticID = MessageID(domain: "ScaffoldMacros", id: message)
    }
}
