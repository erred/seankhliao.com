# splitting my monorepo

## the tooling just isn't there

### _experimenting_ with monorepos

10 months ago,
I consolidated nearly all my code into a single monorepo,
which I creatively called [mono](https://github.com/seankhliao/mono).
And now, I'm break it up back into a constellation of single app repos.

#### _like_

What I liked:

- There isn't any thought into which repo something should go into:
  there's only one.
- It was easy to find all the consumers of a particular piece of code,
  as ecerything was just there
- No need for dependency management on internal things
  everything is on the same version
  (excluding wire api versioning for deployed services)
- force repo to be clean (buildable) all the time

#### _dislike_

Pain points with just a single repo

- _tooling:_
  many tools assume they own an entire directory tree,
  having configuration at the root.
  It's worse if the tools integrate with git (eg `go` vcs stamping),
  as now the root needs to be the repo root.
- _tooling_ on changes only:
  you might want to build only the changed parts,
  but it's not very easy with a monorepo,
  you need all sorts of filtering for different tools,
  and in the end, you have to manage a manual list of dependencies.
  Maybe that's why [Bazel](https://bazel.build/) is the way it is.
- everything had to be on the same version,
  eg [lucas-clemente/quic-go](https://github.com/lucas-clemente/quic-go)
  doesn't build with go `tip`, which is what I want to use most of the time.
- experimental code would constantly break builds,
  there's no leaving things in a half working state if you need to do some other work in between.
