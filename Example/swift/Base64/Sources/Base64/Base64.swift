import Foundation
import NIF

#nifLibrary(name: "Elixir.Base64", functions: [encode(_:), decode(env:_:)])

@nif func encode(_ data: Data) -> Data {
    data.base64EncodedString().data(using: .utf8)!
}

@nif func decode(env: BEAM.Env, _ data: Data) -> BEAM.Term {
    guard let decoded = Data(base64Encoded: data) else {
        return env.makeBadArg()
    }
    return BEAM.Term(decoded, env: env)
}
