# ci in buildkit

## containerizing your builds, the modern(?) way

### _buildkit_

[BuildKit](https://github.com/moby/buildkit) is the core of docker build,
containerizing build steps and providing a directed acyclic graph (DAG) execution engine,
allowing parts to proceed in parallel.
You may have seen this in action with a multistage docker build.
As an independent component,
buildkit isn't limited to docker,
and several tools have emerged that build on top of it,
providing containerized builds with an alternative syntax.

_Note:_ operationally,
this does mean that you/your CI infrastructure has to be capable of
running or connecting to a buildkit daemon that can spawn and run containers.
If your CI is already containerized,
this may be an issue.

#### _earthly_

[earthly.dev](https://earthly.dev/) extends the Dockerfile syntax
and mixes in some Makefile syntax (indenting and significant whitespace?).
From a certain point of view, it could be seen as Dockerfile++,
with native integration for git, conditionals, looping, and outputs, among other things.
If your problem with Dockerfiles was too many layers run sequentially,
this won't save you.

#### _dagger_

[dagger.io](https://dagger.io/) chooses present its api with
[cue](https://cuelang.org/),
with steps that get fully resolved as their dependencies are executed.
So you get to write your build config in a structured language,
but it's a bit unclear from the build definitions on what properties as actually available...
