# oci image to digest

## immutable everything

### _image_ tag to digest

Container images are usually referenced by tag,
maybe a nice semantic version, or maybe a git commit sha.
Whatever the value,
a tag is still a mutable thing,
today it might point at one thing,
a force push later, and tomorrow it points at something else.

To get around that we can reference images (or other artifacts) by digest,
a content hash which can only refer to a single thing.
To resolve a mutable tag to a digest, we have several options:

#### _crane_

[crane], or the [gcrane] variant,
are command line tools for general registry/image manipulation.

[crane]: https://github.com/google/go-containerregistry/tree/main/cmd/crane
[gcrane]: https://github.com/google/go-containerregistry/tree/main/cmd/gcrane

```sh
$ gcrane digest golang:alpine
sha256:ee2f23f1a612da71b8a4cd78fec827f1e67b0a8546a98d257cca441a4ddbebcb
```

#### _cosign_

[cosign] is a tool primarily for signing images/artifacts,
but it notably complains if you try to sign things by tag,
as you might not be signing the thing you thought you were signing.
It has a `triangulate` subcommand for finding where the signature might be,
but we can use that to extract the digest.

[cosign]: https://github.com/sigstore/cosign

```sh
$ cosign triangulate golang:alpine
index.docker.io/library/golang:sha256-ee2f23f1a612da71b8a4cd78fec827f1e67b0a8546a98d257cca441a4ddbebcb.sig

$ cosign triangulate golang:alpine | tr ':-' '@:' | sed 's/\.sig//'
index.docker.io/library/golang@sha256:ee2f23f1a612da71b8a4cd78fec827f1e67b0a8546a98d257cca441a4ddbebcb

$ cosign triangulate golang:alpine | sed -E 's/.*sha256-(.*).sig/\1/'
ee2f23f1a612da71b8a4cd78fec827f1e67b0a8546a98d257cca441a4ddbebcb
```

#### _docker_

docker... just remember to pull the image first,
since it operates locally instead of directly on remote registries like crane and cosign.

```sh
$ docker image inspect golang:alpine | jq -r '.[] | .RepoDigests[]'
golang@sha256:ee2f23f1a612da71b8a4cd78fec827f1e67b0a8546a98d257cca441a4ddbebcb
```
