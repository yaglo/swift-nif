import CErlang
import Foundation

public enum BEAM {
    public typealias Env = OpaquePointer
    public typealias Entry = ErlNifEntry
    public typealias Term = ERL_NIF_TERM
    public typealias Func = ErlNifFunc

    public enum ResourceType { public typealias Init = ErlNifResourceTypeInit }

    @inlinable public static func raiseException(env: BEAM.Env?, reason: BEAM.Term) -> BEAM.Term {
        enif_raise_exception(env, reason)
    }
}

extension BEAM.Env { @inlinable public func makeBadArg() -> BEAM.Term { enif_make_badarg(self) } }

public extension Int32 {
    init?(term: BEAM.Term, env: BEAM.Env?) {
        var int: Int32 = 0

        guard enif_get_int(env, term, &int) != 0 else { return nil }

        self = int
    }
}

public extension Int {
    init?(term: BEAM.Term, env: BEAM.Env) {
        var integer: Int = 0

        guard enif_get_long(env, term, &integer) != 0 else { return nil }

        self = integer
    }
}

public extension Data {
    init?(term: BEAM.Term, env: BEAM.Env?) {
        let binary = UnsafeMutablePointer<ErlNifBinary>.allocate(capacity: 1)

        guard enif_inspect_binary(env, term, binary) != 0 else {
            binary.deallocate()
            return nil
        }

        self.init(bytesNoCopy: binary.pointee.data, count: binary.pointee.size, deallocator: .none)
    }
}

public extension String {}

public extension BEAM.Term {
    @inlinable init(_ term: BEAM.Term, env: BEAM.Env) { self = term }

    @inlinable init(_ integer: Int, env: BEAM.Env) { self = enif_make_long(env, integer) }

    @inlinable init(_ integer: Int32, env: BEAM.Env) { self = enif_make_int(env, integer) }

    @inlinable init(_ string: String, env: BEAM.Env) {
        self = string.withCString { ptr in enif_make_string(env, ptr, ERL_NIF_UTF8) }
    }

    @inlinable init(_ data: consuming Data, env: BEAM.Env) {
        let ptr = UnsafeMutablePointer<ErlNifBinary>.allocate(capacity: 1)
        ptr.pointee.size = data.count
        ptr.pointee.data = UnsafeMutablePointer<UInt8>.allocate(capacity: data.count)
        data.copyBytes(to: ptr.pointee.data, count: data.count)
        self = enif_make_binary(env, ptr)
    }

    func isAtom(env: BEAM.Env) -> Bool { enif_is_atom(env, self) != 0 }

    func isBinary(env: BEAM.Env) -> Bool { enif_is_binary(env, self) != 0 }

    func isEmptyList(env: BEAM.Env) -> Bool { enif_is_empty_list(env, self) != 0 }
}

public extension String {
    func allocCString() -> UnsafePointer<CChar> {
        var str = self
        return str.withUTF8 { bufPtr in
            bufPtr.withMemoryRebound(to: CChar.self) { bufPtr in
                let ptr = UnsafeMutablePointer<CChar>.allocate(capacity: bufPtr.count)
                ptr.initialize(from: bufPtr.baseAddress!, count: bufPtr.count)
                return UnsafePointer(ptr)
            }
        }
    }
}
