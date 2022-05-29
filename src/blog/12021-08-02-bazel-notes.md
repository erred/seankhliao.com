# bazel notes

## that fancy build system

### _bazel_

[bazel](https://bazel.build/), an open implementation of google's build system,
aiming to handle incremental builds across multiple languages.
Written in java, it runs in a client-server model.

#### _crash_ course

##### _bazel_ command

You could install bazel directly,
but a better idea is to install [bazelisk](https://github.com/bazelbuild/bazelisk)
as `bazel`, and it will look at a `.bazelversion` file to determine the version of bazel
to download and run.

Most commands to bazel take targets,
which look like `//dir/from/workspace/root:label`.
Omitting`//` makes it relative,
omitting the path means current,
`...` expands to recursive all.
Labels are the names given to the build targets,
eg a library, an executable, a container image, etc.

##### _WORKSPACE_

The `WORKSPACE` file denotes the root of a workspace (generally repo).
Inside are declarations of dependencies and some metadata.

While bazel config files (`WORKSPACE`, `BUILD`) may look declarative,
they're actually (restricted starlark) code,
which means the ordering of the macros/function calls are important:
[ref](https://jayconrod.com/posts/115/organizing-bazel-workspace-files).
This unfortunately also means tools like
[buildifier](https://github.com/bazelbuild/buildtools/tree/master/buildifier)
are limited in what they can do to organize/format the config files.

Functions need to be loaded before use,
dependencies that follow best practices usually have them centrally declared
in a `def.bzl` file.

```bzl
load("@com_github_bazelbuild_buildtools//buildifier:def.bzl", "buildifier")
```

Dependencies (repository rules:, `http_archive`, `git_repository`, ...)
can be declared multiple times,
and the version selected is the last declared version before first use.
Rules you import (ex gazelle) may have dependencies that you also need,
and well behaved ones will have code like the below to not override your choices,
so declare your dependencies first before you use them.

```bzl
def buildifier_dependencies():
    _maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = "7363ae6721c1648017e23a200013510c9e71ca69f398d52886ee6af7f26af436",
        strip_prefix = "bazel-skylib-c00ef493869e2966d47508e8625aae723a4a3054",
        url = "https://github.com/bazelbuild/bazel-skylib/archive/c00ef493869e2966d47508e8625aae723a4a3054.tar.gz",  # 2018-12-06
    )

def _maybe(repo_rule, name, **kwargs):
    if name not in native.existing_rules():
        repo_rule(name = name, **kwargs)
```

As fair as I can tell,
there isn't a good package manager
so you're sort of stuck copy-pasting a lot of `sha256`s and urls.

##### _BUILD_

The build files declare the things you want to be able to output for a given directory.
Ex the following builds:
a go executable, a container image, and a target to push the image to a remote registry.

```bzl
load("@io_bazel_rules_go//go:def.bzl", "go_binary", "go_library")

go_library(
    name = "archrepod_lib",
    srcs = [
        "doc.go",
        "main.go",
    ],
    importpath = "go.seankhliao.com/mono/go/cmd/archrepod",
    visibility = ["//visibility:private"],
    deps = [
        "//go/internal/archrepo/server",
        "//go/webserver",
    ],
)

go_binary(
    name = "archrepod",
    embed = [":archrepod_lib"],
    visibility = ["//visibility:public"],
    pure= "on",
)

load("@io_bazel_rules_docker//container:container.bzl", "container_image")

container_image(
    name = "image",
    base = "@go_image_static//image",
    files = [":archrepod"],
    entrypoint = ["/archrepod"],
)

load("@io_bazel_rules_docker//container:container.bzl", "container_push")

container_push(
    name = "push",
    format = "OCI",
    image = ":image",
    registry = "europe-north1-docker.pkg.dev",
    repository = "com-seankhliao/kluster/archrepod",
    skip_unchanged_digest = True,
)
```

#### _go_

[rules_go](https://github.com/bazelbuild/rules_go)
contains the basic rules for building things with go,
though most of the time you'll be using
[gazelle](https://github.com/bazelbuild/bazel-gazelle)
to detect changes / update your BUILD config.
As long as your `go.mod` contains an up to date set of dependencies,
`bazel run //:gazelle -- update-repos -from_file=go.mod -prune`
should do most of the heavy lifting for you.

You may occasionally need to adjust the output,
such as setting `pure = on` in a build target
or `build_file_generation = "on"` in a `go_repository`
to override a dependency (that also uses bazel)'s broken BUILD config.

##### _protobuf_ grpc

Having bazel handle everything means you only have `.proto` files
and the corresponding generated files exist only in the build output dirs.
This is a problem both for editors ((neo)vim + gopls)
and for any downstream consumers you may have.
So you may decide to skip having bazel generate the files
and just generate + check them in.

##### _other_ go problems

for some reason, bazel always wants to rebuild the C protobuf compiler...

#### _container_

[rules_docker](https://github.com/bazelbuild/rules_docker)
contains rules for building container images without a docker daemon.
Note you can really on create/place files and not run commands,
and you'll have to do it via BUILD files.

While you could use the language specific rules,
at least for minimal go images,
i think `container_image` makes more sense.
`go_image_static` is declared in `rules_docker`
to be `gcr.io/distroless/static` at some version pinned in there.
This just uses the executable from a previous rule as the only file and entrypoint.

```bzl
container_image(
    name = "image",
    base = "@go_image_static//image",
    files = [":archrepod"],
    entrypoint = ["/archrepod"],
)
```

#### _k8s_ gitops

Both
[rules_k8s](https://github.com/bazelbuild/rules_k8s)
(k8s manifests with replacements via string / targets)
and [rules_gitops](https://github.com/adobe/rules_gitops)
(kustomize in BUILD)
exist though i've tested neither
(too much effort to rewrite manifests).

#### _bazel_ run

Exectables are built in a sandbox (ex during `bazel build //cmd/helloworld:exe`)
and can be run with `bazel run //cmd/helloworld:exe -- args go here`.
By default it's in a sort of sandbox (doesn't seem very effective?)
but it can change to the working directory or workspace root
through reading the envs `BUILD_WORKING_DIRECTORY` or `BUILD_WORKSPACE_DIRECTORY`,
[ref](https://docs.bazel.build/versions/main/user-manual.html#run).

I have yet to figure out how to create a target
that has the args encoded to modify the source files (like gazelle...).
