import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main struct NIFMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [NIFMacro.self, NIFLibraryMacro.self]
}

enum NIFMacroError: Error {
    case onlyApplicableToFunction
    case moduleNameNotProvided
    case functionsNotProvided
    case canOnlyPassFunctionReferences
}

public struct NIFMacro: PeerMacro {
    public static func expansion(
        of node: SwiftSyntax.AttributeSyntax,
        providingPeersOf declaration: some SwiftSyntax.DeclSyntaxProtocol,
        in context: some SwiftSyntaxMacros.MacroExpansionContext
    ) throws -> [SwiftSyntax.DeclSyntax] {
        guard let function = declaration.as(FunctionDeclSyntax.self) else {
            throw NIFMacroError.onlyApplicableToFunction
        }

        let allArguments = function.signature.parameterClause.parameters.map {
            (name: $0.firstName.text, type: $0.type.description)
        }
        let firstArgIsEnv = allArguments.first?.name == "env" && allArguments.first?.type == "BEAM.Env"
        let arguments = if firstArgIsEnv { Array(allArguments.dropFirst()) } else { allArguments }

        let guards =
            ["guard argc == \(arguments.count), let argv"]
            + arguments.enumerated().map { i, arg in "let arg\(i) = \(arg.type)(term: argv[\(i)], env: env)" }
        return [
            DeclSyntax(
                stringLiteral: """
                    public func __nif_thunk_\(function.name.text)(_ env: BEAM.Env!, _ argc: Int32, _ argv: UnsafePointer<BEAM.Term>?) -> BEAM.Term {
                        \(guards.joined(separator: ", ")) else { return env.makeBadArg() }
                        return BEAM.Term(\(function.name.text)(\(firstArgIsEnv ? "env: env, " : "")\(arguments.enumerated().map { i, t in "\(t.name): arg\(i)" }.joined(separator: ", "))), env: env)
                    }
                    """
            )
        ]
    }
}

public struct NIFLibraryMacro: DeclarationMacro {
    public static func expansion(of node: some FreestandingMacroExpansionSyntax, in context: some MacroExpansionContext)
        throws -> [DeclSyntax]
    {
        guard
            let moduleName = node.argumentList.first(where: { $0.label?.text == "name" })?.expression
                .as(StringLiteralExprSyntax.self)?
                .representedLiteralValue
        else { throw NIFMacroError.moduleNameNotProvided }

        guard
            let functions = try node.argumentList.first(where: { $0.label?.text == "functions" })?.expression
                .as(ArrayExprSyntax.self)?
                .elements
                .compactMap({
                    guard let declExpr = $0.expression.as(DeclReferenceExprSyntax.self) else {
                        throw NIFMacroError.functionsNotProvided
                    }
                    return declExpr
                })
        else { throw NIFMacroError.functionsNotProvided }

        return [
            DeclSyntax(
                stringLiteral: """
                    @_cdecl("nif_init")
                    func nif_init() -> UnsafePointer<BEAM.Entry> {
                        let entry = UnsafeMutablePointer<BEAM.Entry>.allocate(capacity: 1)

                        entry.initialize(to: .init(
                            major: 2,
                            minor: 17,
                            name: "\(moduleName)".allocCString(),
                            num_of_funcs: \(functions.count),
                            funcs: funcs(),
                            load: nil,
                            reload: nil,
                            upgrade: nil,
                            unload: nil,
                            vm_variant: "beam.vanilla".allocCString(),
                            options: 1,
                            sizeof_ErlNifResourceTypeInit: MemoryLayout<BEAM.ResourceType.Init>.size,
                            min_erts: "erts-14.0".allocCString()))

                        return UnsafePointer(entry)


                        func funcs() -> UnsafeMutablePointer<BEAM.Func> {
                            let funcs = UnsafeMutablePointer<BEAM.Func>.allocate(capacity: \(functions.count))
                            \(functions.enumerated().map { i, f in """
                                funcs[\(i)] = BEAM.Func(name: "\(f.baseName.text)".allocCString(), arity: \(
                                f.argumentNames?.arguments.as(DeclNameArgumentListSyntax.self)?.first?.as(DeclNameArgumentSyntax.self)?.name.text == "env"
                                ? (f.argumentNames?.arguments.count ?? 1) - 1
                                : f.argumentNames?.arguments.count ?? 0
                            ), fptr: \(f.baseName.text)(_:_:_:), flags: 0)
                            """}.joined())
                            return funcs

                    \(functions.map { f in """
                    func \(f.baseName.text)(_ env: OpaquePointer?, _ argc: Int32, _ argv: UnsafePointer<BEAM.Term>?) -> BEAM.Term {
                        __nif_thunk_\(f.baseName.text)(env, argc, argv)
                    }
                    """}.joined())
                        }
                    }

                    """
            )
        ]
    }
}

//                f.argumentNames?.arguments.as(DeclNameArgumentListSyntax.self)?.first?.as(DeclNameArgumentSyntax.self)?.name == "env"
