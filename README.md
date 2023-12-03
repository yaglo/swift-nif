# SwiftNIF - Erlang and Elixir NIFs in Swift

This is a quick prototype of a library for writing Native Implemented Functions
(NIFs) for Erlang and Elixir. It uses Swift macros to generate the necessary
boilerplate for module definition and C interoperability, including conversion
between Erlang terms and Swift data types.

## Example

```swift

import NIF

#nifLibrary(name: "adder", functions: [add(_:)])

@nif func add(_ a: Int, _ b: Int) -> Int {
    a + b
}
```

The `#nifLibrary` and `@nif` will generate all the necessary boilerplate so
that you will be able to use it like this, for example, in Erlang:

```erlang
-module(adder).

-export([init/0, add/2]).

-nifs([add/2]).

-on_load(init/0).

init() ->
      erlang:load_nif("./adder", 0).

add(_, _) ->
      erlang:nif_error("NIF library not loaded").
```

If you need some advanced working with the Erlang's environment, right now, if
the first argument is `env:`, you will be able to use it like this:

```swift
@nif func decode(env: BEAM.Env, _ data: Data) -> BEAM.Term {
    guard let decoded = Data(base64Encoded: data) else {
        return env.makeBadArg()
    }
    return BEAM.Term(decoded, env: env)
}
```

See the `Example` folder with an example of its usage in Elixir.