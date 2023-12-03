@_exported import NIFSupport

@attached(
    peer,
    names: prefixed(__nif_thunk_),
    suffixed(_0),
    suffixed(_1),
    suffixed(_2),
    suffixed(_3),
    suffixed(_4),
    suffixed(_5),
    suffixed(_6),
    suffixed(_7),
    suffixed(_8)
)
public macro nif() = #externalMacro(module: "NIFMacros", type: "NIFMacro")

@freestanding(declaration, names: named(nif_init))
public macro nifLibrary(name: String, functions: [Any]) = #externalMacro(module: "NIFMacros", type: "NIFLibraryMacro")
