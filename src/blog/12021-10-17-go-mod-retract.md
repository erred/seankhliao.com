# go.mod retract

## how to retract module (versions)


### _retract_

The Go module ecosystem is based on the concept of _immutable_ versions.
Once a module version is published, the contents must never change.
This is enforced by global proxies (and their sum databases)
and locally in consumers via `go.sum` files.

Now, if you make a mistake or change your mind,
the only way around is to publish new, higher versions.
You may also want to affect how downstream users select versions,
maybe telling them not to use specific versions through `retract`.

The [`retract`](https://golang.org/ref/mod#go-mod-file-retract)
is part of a module's `go.mod` file,
and `go` uses the contents of the highest published version
to determine which versions are retracted (meaning you could un-retract something if you wish)

#### _basic_ uses

##### _retract_ single version

Publish a newer version (ex `v0.1.1`) with `go.mod`:

```gomod
module example.com/retract-single

go 1.17

retract v0.1.0
```

##### _retract_ range of version

Publish a newer version (ex `v0.2.1`) with `go.mod`:

```gomod
module example.com/retract-range

go 1.17

retract [v0.1.0, v0.2.0]
```

##### _retract_ commits

You haven't started using tagging with [semver](https://semver.org/)
or you just want to retract a commit in between published versions.

This makes use of [pseudo-versions](https://golang.org/ref/mod#pseudo-versions),
Go's way of representing individual commits within semver.
The easiest way to determine the correct one is `go list -m example.com/module@commit`.

```gomod

module example.com/retract-commits

go 1.17

retract (
        // v0.0.0 if there are no versions
        // yyyymmddhhmmss commit UTC timestamp
        // 12 char commit hash prefix
        v0.0.0-20211017055555-1234567890ab

        // everything after v0.1.0, up to and including v0.2.0
        [v0.1.1-0.00000000000000-000000000000, v0.2.0]
)
```

#### _common_ usecases

##### _back_ to unversioned

You had versioned tags, but now you regret it and want to go back to no versioning.

Say you're already at `v0.15.1`, publish a `v0.15.2` with:

```gomod
module example.com/retract-tagged

go 1.17

// retract all published versions, including the version that includes this retraction
retract [v0.0.0, v0.15.2]
```

##### _wipe_ out a module

You want to remove all possible versions

Say you're already at `v0.15.1`, publish a `v0.15.2` with:

```gomod
module example.com/retract-all

go 1.17

// retract all versions, including the versions individual commits would have,
// and also the version that contains this retraction
retract [v0.0.0-00000000000000-000000000000, v0.15.2]
```
