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
        let trackedFunctions = try filterTrackedFunctions(functions, coordinatableType: coordinatableType, context: context)

        let destinationsEnum = try generateDestinationsEnum(
            className: className,
            functions: trackedFunctions,
            accessModifier: accessModifier,
            codable: codable
        )

        var members: [DeclSyntax] = [DeclSyntax(destinationsEnum)]

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
                
                let trackedFunction = try TrackedFunction(
                    function: function,
                    returnType: returnTypeInfo,
                    branches: conditional.branches
                )
                trackedFunctions.append(trackedFunction)
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
            $0.wrapping($0.availabilityAttributes + (try generateEnumCaseDecl(for: $0)).description)
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
        let docTrivia = generateDocumentationTrivia(for: function)
        
        if function.parameters.isEmpty {
            let enumCaseDecl = EnumCaseDeclSyntax {
                EnumCaseElementSyntax(name: .identifier(function.name))
            }
            
            return enumCaseDecl.with(\.leadingTrivia, docTrivia)
        } else {
            let params = function.parameters.enumerated().map { (index, param) in
                let isLast = index == function.parameters.count - 1
                
                if let label = param.label {
                    return EnumCaseParameterSyntax(
                        firstName: .identifier(label),
                        colon: .colonToken(),
                        type: IdentifierTypeSyntax(name: .identifier(param.type)),
                        defaultValue: param.defaultValue.map {
                            InitializerClauseSyntax(value: ExprSyntax(stringLiteral: $0))
                        },
                        trailingComma: isLast ? nil : .commaToken()
                    )
                } else {
                    return EnumCaseParameterSyntax(
                        type: IdentifierTypeSyntax(name: .identifier(param.type)),
                        defaultValue: param.defaultValue.map {
                            InitializerClauseSyntax(value: ExprSyntax(stringLiteral: $0))
                        },
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
            
            return enumCaseDecl.with(\.leadingTrivia, docTrivia)
        }
    }
    
    private static func generateDocumentationTrivia(for function: TrackedFunction) -> Trivia {
        let returnTypeString = getActualReturnTypeString(from: function.originalFunction)
        let functionBodyLines = extractFunctionBodyLines(from: function.originalFunction)
        
        var triviaPieces: [TriviaPiece] = [
            .docLineComment("/// ```swift"),
            .newlines(1),
            .docLineComment("/// \(returnTypeString)"),
            .newlines(1),
            .docLineComment("/// ```"),
            .newlines(1),
            .docLineComment("///"),
            .newlines(1),
            .docLineComment("/// Function body"),
            .newlines(1),
            .docLineComment("/// ```swift"),
            .newlines(1)
        ]
        
        for line in functionBodyLines {
            triviaPieces.append(.docLineComment("/// \(line)"))
            triviaPieces.append(.newlines(1))
        }
        
        triviaPieces.append(.docLineComment("/// ```"))
        triviaPieces.append(.newlines(1))
        
        return Trivia(pieces: triviaPieces)
    }
    
    private static func extractFunctionBodyLines(from function: FunctionDeclSyntax) -> [String] {
        guard let body = function.body else {
            return ["{ }"]
        }
        
        // Extract the statements from the function body
        let statements = body.statements
        
        if statements.count == 1, let returnStmt = statements.first?.item.as(ReturnStmtSyntax.self) {
            // Single return statement - extract just the expression
            if let expression = returnStmt.expression {
                let expressionString = expression.description
                return preserveFormattingLines(expressionString)
            }
        } else if statements.count == 1 {
            // Single expression statement (implicit return)
            let statement = statements.first!.item
            let statementString = statement.description
            return preserveFormattingLines(statementString)
        } else {
            // Multiple statements - return the whole body
            let bodyContent = statements.map { stmt in
                stmt.description
            }.joined(separator: "\n")
            return preserveFormattingLines(bodyContent)
        }
        
        return ["{ }"]
    }
    
    private static func preserveFormattingLines(_ text: String) -> [String] {
        let lines = text.components(separatedBy: .newlines)
        
        let trimmedLines = lines.drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .reversed()
            .drop { $0.trimmingCharacters(in: .whitespaces).isEmpty }
            .reversed()
        
        return Array(trimmedLines)
    }
    
    private static func getActualReturnTypeString(from function: FunctionDeclSyntax) -> String {
        guard let returnClause = function.signature.returnClause else {
            return "Void"
        }
        
        return returnClause.type.trimmedDescription.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
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
    
    init(function: FunctionDeclSyntax, returnType: ReturnTypeInfo, branches: [ConditionalBranch]) throws {
        self.branches = branches
        self.name = "`" + function.name.text.replacingOccurrences(of: "`", with: "") + "`"
        self.returnType = returnType
        self.originalFunction = function
        self.parameters = try function.signature.parameterClause.parameters.map { param in
            try Parameter(from: param)
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

struct Parameter {
    let label: String?
    let type: String
    let defaultValue: String?
    let isAutoclosure: Bool
    
    init(from param: FunctionParameterSyntax) throws {
        // Handle parameter labels
        if param.firstName.text != "_" {
            self.label = "`" + param.firstName.text.replacingOccurrences(of: "`", with: "") + "`"
        } else {
            self.label = nil
        }
        
        var storedType = param.type
        if var attributed = storedType.as(AttributedTypeSyntax.self) {
            self.isAutoclosure = attributed.attributes.contains {
                $0.as(AttributeSyntax.self)?.attributeName.trimmedDescription == "autoclosure"
            }
            attributed.attributes = attributed.attributes.filter {
                guard let attribute = $0.as(AttributeSyntax.self) else { return true }
                return !["escaping", "autoclosure"].contains(attribute.attributeName.trimmedDescription)
            }
            storedType = TypeSyntax(attributed)
        } else {
            self.isAutoclosure = false
        }
        self.type = storedType.trimmedDescription
        if let value = param.defaultValue?.value.trimmedDescription {
            self.defaultValue = isAutoclosure ? "{ \(value) }" : value
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
