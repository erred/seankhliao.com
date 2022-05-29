# outsider's view of wasm

## WebAssembly, the next generation JVM?


### _WebAssembly_

[WebAssembly (Wasm)](https://webassembly.org/)
"is a binary instruction format for a stack-based virtual machine".
In plainer words, wasm is a format of an executable that a compiler can compile to
and a runtime can run.

How is this different from say the Java Virtual Machine (JVM)?
Arguably, within the JVM ecosystem,
the JVM came first and languages were designed for it and around its perculiarities.
Wasm came much later,
instead targeting existing languages by exposing a lower level,
more minimal interfaces that existing languages/compilers can target as just another architecture.

Wasm itself is fairly low-level, so on top of that,
there's a [Web API](https://webassembly.github.io/spec/web-api/index.html) for integration with browsers,
[JavaScript API](https://webassembly.github.io/spec/js-api/index.html) for JS,
and [WASI](https://wasi.dev/) for a generic interface for life outside the web/browser.

#### _Writing_ Wasm

[Go](https://go.dev/): While `go` has a `GOOS=js GOARCH=wasm` target, it targets the web,
and also requires extra js to setup everything. Instead, you'll want _tinygo_

[TinyGo](https://tinygo.org/): Go, but targeting embedded systems and wasm.
It's not a full drop in replacement
(see [language support](https://tinygo.org/docs/reference/lang-support/)),
but good enough.

[Rust](https://www.rust-lang.org/):
Supports a [`wasm-wasi`](https://doc.rust-lang.org/nightly/rustc/platform-support.html#tier-2)
target at Tier 2, most tutorials will have you writing rust.

#### _Packaging_ and Distrobution

You have code, and you have a compiled binary that can run everywhere (that a runtime supports),
so how do you get that from your development machine to your deployment machine?

Most projects appear to be piggybacking on top of the
[Open Containers Initiative (OCI)](https://opencontainers.org/) [artifacts](https://github.com/opencontainers/artifacts),
who have defined a well supported image/metadata format that can support arbitrary data.
Alternatives include [wasmer wapm](https://wapm.io/),
[wasm-pack](https://github.com/rustwasm/wasm-pack) on top of NPM,
[bindle](https://docs.hippofactory.dev/topics/concepts/#bindle) for Hippo,
[bundle](https://docs.suborbital.dev/atmo/concepts/glossary) for Suborbital / Atmo,
etc.

#### _Running_ Wasm

As a non native (hardware) instruction format,
code compiled to wasm needs a runtime to run.
There are [quite a few](https://github.com/appcypher/awesome-wasm-runtimes),
some are simple runtimes,
while others are part of a wider development/deployment suite.
Some notable ones:

[WasmEdge](https://wasmedge.org/) integrates with crun / containerd,
allowing projects that use those (K8s and its extended ecosystem)
to easily schedule / manage / run wasm code.

[Krustlet](https://docs.krustlet.dev/) integrates directly with the kubernetes API,
exposing itself as a node/kubelet that can run wasm binaries from OCI registries.

[Suborbital / Atmo](https://suborbital.dev/),
[wasmCloud](https://wasmcloud.dev/),
[Hippo](https://docs.hippofactory.dev/)
all look like integrated build tooling + deployment platform / servers.

Alternatively, you can also use wasm for libraries / plugins,
exposing functions instead of a full application.
For Go:
[Wasmtime](https://pkg.go.dev/github.com/bytecodealliance/wasmtime-go),
[WasmEdge](https://pkg.go.dev/github.com/second-state/WasmEdge-go/wasmedge)
[Wasmer](https://pkg.go.dev/github.com/wasmerio/wasmer-go@v1.0.4/wasmer)
all provide SDKs that make it easy.
