# bazel and go, 2023

## notes and bazel

### _bazel_ and go

Occasionally, I think "it would be nice if everything could be built together in one tool",
and I inevitable think of [bazel](https://bazel.build/).
Well this is my 2023 attempt to try and use it.

#### _getting_ started

We start with not bazel itself, but [bazelisk](https://github.com/bazelbuild/bazelisk),
a wrapper around `bazel` that will handle downloading and running the correct version of `bazel` for you.
Obtain `bazelisk` through **magic** (like OS repositories), install it as `bazel`,
and we're good to go.
We'll want to choose a version of `bazel` though
and record that in `.bazelversion` for `bazelisk` to pick up:

```sh
$ echo 6.4.0 > .bazelversion
```

Next we need to define a [bazel workspace](https://bazel.build/concepts/build-ref#workspace),
the root of everything that will be built by `bazel`.
The previous link used `WORKSPACE` or `WORKSPACE.bazel`,
which is also where you'd put all the directives to download external dependencies,
but bazel is in the process of moving to [modules](https://bazel.build/external/module)
where dependencies come from central registries like [registry.bazel.build],
so we can replace that with a `MODULE.bazel` file.
We declare a module using [module](https://bazel.build/rules/lib/globals/module#bazel_dep):

```bzl
# MODULE.bazel

module(name = "example_repo1", version = "0.0.1")
```

Bazel modules also have to be enabled with a flag right now,
which can be passed to every command via `.bazelrc`:

```sh
$ echo "common --enable_bzlmod" > .bazelrc
```

#### _basic_ tools

There are some tools that might be considered almost mandatory:

- [buildifier](https://github.com/bazelbuild/buildtools/tree/master/buildifier) for formatting of bazel/starlark files
- [buildozer](https://github.com/bazelbuild/buildtools/tree/master/buildozer) for rewriting `BUILD` files
- [gazelle](https://github.com/bazelbuild/bazel-gazelle) for generating `BUILD` files from other places like `go.mod`

From [registry.bazel.build] we can find
[buildifier_prebuilt](https://registry.bazel.build/modules/buildifier_prebuilt)
and [gazelle](https://registry.bazel.build/modules/gazelle).
We can add them to `MODULE.bazel` using [bazel_dep](https://bazel.build/rules/lib/globals/module#bazel_dep):

```bzl
# MODULE.bazel

bazel_dep(name = "gazelle", version = "0.33.0", dev_dependency = True)
bazel_dep(name = "buildifier_prebuilt", version = "6.3.3", dev_dependency = True)
```

Finally, we can load extensions and register targets in `BUILD.bazel`.

```bzl
# BUILD.bazel

load("@gazelle//:def.bzl", "gazelle")
gazelle(name = "gazelle")

load("@buildifier_prebuilt//:rules.bzl", "buildifier")
buildifier(name = "buildifier")
```

This should mean we can run commands like:

```sh
$ bazel run //:buildifier # formats files
```

#### _go_ go go

Time to write some Go code.
We'll still try to be compatible with vanilla `go`
(and it's nicer to manage deps this way) so:

```sh
$ go mod init repo1.example
```

and let's write some very simple code:

```sh
$ mkdir helloworld
$ cat << EOF > helloworld/main.go
package main

import "fmt"

func main() {
	fmt.Println("hello world")
}
EOF
```

We can run it with `go`:

```sh
$ go run ./helloworld
```

But to run it with `bazel` we'll need some rules for building go,
specifically [rules_go](https://registry.bazel.build/modules/rules_go):

```bzl
# MODULE.bazel

bazel_dep(name = "rules_go", version = "0.42.0")
```

Then we can generate the `BUILD.bazel` files with gazelle:

```sh
$ bazel run //:gazelle

# results
$ cat helloworld/BUILD.bazel
load("@rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "helloworld_lib",
    srcs = ["main.go"],
    importpath = "repo1.example/helloworld",
    visibility = ["//visibility:private"],
)

go_binary(
    name = "helloworld",
    embed = [":helloworld_lib"],
    visibility = ["//visibility:public"],
)

# build and run
$ bazel run //helloworld

# or without build logs
$ bazel run --ui_event_filters=-info,-stdout,-stderr --noshow_progress //helloworld
```

Just run `bazel run //:gazelle` every time new packages are created or imports change.

#### _external_ go dependency

Now for external dependencies.
We start with a simple piece of code borrowed from the [Go tutorial](https://go.dev/doc/tutorial/getting-started#call)

```sh
$ mkdir helloworld2
$ cat << EOF > helloworld2/main.go
package main

import (
	"fmt"

	"rsc.io/quote"
)

func main() {
	fmt.Println(quote.Go())
}
EOF
```

We'll want to run `go mod tidy` to get the dep in `go.mod`:

```sh
$ bazel run @rules_go//go -- mod tidy
```

We'll also want to use gazelle to sync deps from `go.mod` into the bazel module system:

```bzl
# MODULE.bazel
go_deps = use_extension("@gazelle//:extensions.bzl", "go_deps")
go_deps.from_file(go_mod = "//:go.mod")
```

Then we can run gazelle, which should give us a warning about needing to actually register the module

```sh
$ bazel run //:gazelle
WARNING: /home/arccy/tmp/testrepo0416/MODULE.bazel:10:24: The module extension go_deps defined in @gazelle//:extensions.bzl reported incorrect imports of repositories via use_repo():

Not imported, but reported as direct dependencies by the extension (may cause the build to fail):
    io_rsc_quote

 ** You can use the following buildozer command to fix these issues:

buildozer 'use_repo_add @gazelle//:extensions.bzl go_deps io_rsc_quote' //MODULE.bazel:all
```

Run the suggested command to add the dep to `MODULE.bazel`
which should now have `use_repo(go_deps, "io_rsc_quote")`.
And we should finally be able to run:

```sh
$ bazel run //helloworld2
```

Note that it appears we can't run `buildozer` via `bazel` itself because we can't escape the sandbox,
and I don't understand enough of `bazel` to make it work.
(apparently it's not too hard: [aspect blog](https://www.aspect.dev/blog/bazel-can-write-to-the-source-folder))

[registry.bazel.build]: https://registry.bazel.build/
