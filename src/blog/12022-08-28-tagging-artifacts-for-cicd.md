# tagging artifacts for cicd

## because a git sha is devoid of information

### _tagging_ artifacts

In the brave new world of building and deploying every commit
(Continuous Integration / Continuous Deployment, CI/CD),
for every commit in your git repo,
you need to build it,
outputting a binary artifact, an executable or an entire container image.
Now comes the problem: how do you organize and keep track of it?

Here's a list of ways to tag things:

- a forever up to date tag: `latest`:
  mutable tag, definition depends on time,
  race conditions for parallel builds
- a semantic version: `v1.2.3`:
  not necessarily immutable,
  may change depending on time,
  tedious for every commit,
  litters git history
- full git sha `git rev-parse HEAD`: `879cd74c89efdedd0693b4a7b8416321712c3a07`:
  too long, doesn't sort well,
  requires the source repo to get any other info,
  eg age estimate
- short git sha `git rev-parse --short HEAD`: `879cd74`:
  shorter version of the above
- go [pseudoversions](https://go.dev/ref/mod#pseudo-versions):
  `v0.0.0-0.yyyymmddhhmmss-abcdefabcdef`:
  sorts like semver,
  can incorporate tags, encodes both a time estimate (commit time) and git commit,
  only works for fully reproducible builds
- pseudoversions with build identifier:
  `v0.0.0-0.yyyymmddhhmmss-abcdefabcdef+buildid`:
  same as above, but incorporates a build id (eg CI run),
  allows tracking down the provenance of the build.

Even with all of the above, if you're using containers,
nothing technically prevents you from modifying tags.
Instead you should consider also use image digests `some/image@sha256:abc...123`,
and maybe store authenticated metadata in a separate artifact,
eg with [`cosign`](https://github.com/sigstore/cosign).
You may still want that tagging, so cleaning up old artifacts is easier...
