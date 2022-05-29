# unpublishing go modules

## or as close as you can get


### _unpublishing_ go modules

_tldr:_ `retract [v0.0.0-0, vX.Y.Z]` and publish a new version at `vX.Y.Z`

Go, by default, uses [module proxies](https://go.dev/ref/mod#module-proxy) to fetch dependencies,
which brings speed advantages (a `GET` is faster than a bunch of VCS operations)
and also some reliability improvements (if your proxy can permanently cache things).
The default proxy, [proxy.golang.org](https://proxy.golang.org/)
(also used by [pkg.go.dev](https://pkg.go.dev/))
caches most things more or less permanently,
reducing the impact of `left-pad` type situations (where dependencies just disappear).

#### _usecases_

So why might you want to unpublish something?

##### _undo_ multi module

For example: you have a module at `github.com/foo/bar`
and you decided to experiment with with a multi module configuration,
creating `github.com/foo/bar/cmd/bar`.
Now you want to more or less undo that.
Because of the permanent cache and [longest module path wins](https://go.dev/ref/mod#resolve-pkg-mod),
removing the module from your source repo isn't enough.
This is especially apparent for tools installed with `go install pkg@latest`.

##### _wiping_ a repo

You no longer want to keep the repo,
and you also want `pkg.go.dev` to stop displaying documentation for it.
You should do this before you actually wipe out the repo.

#### _retract_

You'll want to use the [`retract`](https://go.dev/ref/mod#go-mod-file-retract) directive.
It can take a range of versions, like `retract [v0.0.1, v0.0.5]`.

_Note:_ the code will still live on in the proxy,
stopping existing builds from breaking,
but new code shouldn't, by default, add it as a new direct dependency.

##### _start_

What version do you start retracting from?
If you're wiping out something entirely, `v0.0.0-0` is a good choice.

_Explanation:_ go uses [semver](https://semver.org/) for versions.
To make plain commits fit within semver and order properly,
go uses [pseduo-versions](https://go.dev/ref/mod#pseudo-versions),
these are generated, valid semver ids that represent individual commits,
and order correctly in the context of other non generated versions.
`v0.0.0` is the base version,
but prereleases order before the actual release so we need one of those.
Within prerelease identifiers,
shorter sets (dot separated) order first,
and numeric identifiers order before strings, so `0` is the earliest prerelease possible.

##### _end_

What version do you end at retracting?
If you've never published tags for it, you could use `v0.0.1`.
If you have, then the next version up works fine.
The important thing here is you can retract the same version that is publishing the retraction.

##### _publishing_

So you have a `retract [v0.0.0-0, v1.5.6]` directive in the `go.mod`.
What next?
You'll have to publish it with `v1.5.6`:

- create the tag
  - `v1.5.6` if it's the repo root
  - `path/from/root/v1.5.6` if it's a multi module repo
- push it to your repo
- pull the module/version through the proxy to make it aware of the retraction.
  - in some temporary module `go get your/module@v1.5.6`

_Note:_ because we're using tags,
this doesn't have to happen on the main branch of the repo.
You could create an empty branch, say `retractions`,
with just the `go.mod` containing the `module ....` and `retract` in it.

#### _example_

You have a multi module repo and you want to move back to a single module:

```gomod
// /go.mod
module github.com/foo/bar

// published tags:
// v0.1.0
// v0.2.0
// v0.3.0
// v0.4.0
```

and

```gomod
// /cmd/bar/go.mod
module github.com/foo/bar/cmd/bar

// published tags:
// cmd/bar/v0.3.0
// cmd/bar/v0.4.0
```

You should:

On a non default branch tag this as `cmd/bar/v0.5.0`
(If you use the default branch,
your next commit after the tag should remove to `go.mod` file entirely).

```gomod
// /cmd/bar/go.mod
module github.com/foo/bar/cmd/bar

retract [v0.0.0-0, v0.5.0]
```

Tag a new release of the module at the root (`github.com/foo/bar`)
so downstream users will have a working way of getting the content in `cmd/bar`.
Ex: `v0.4.1`.
