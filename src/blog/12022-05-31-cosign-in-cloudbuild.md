# cosign in cloudbuild

## signing the things you wanted

### _signing_ container images

[Sigstore](https://www.sigstore.dev/)'s
[cosign](https://docs.sigstore.dev/cosign/overview)
is the new, widely supported way of signing container images.

Of particular interest is the [keyless](https://docs.sigstore.dev/cosign/openid_signing)
OpenID signing flow:
it proves a time-constrained signing identity,
vs an unconstrained signing identity you usually get with static / long-lived keys.

#### _cloudbuild_

To use it in cloudbuild:

```yaml
steps:
  - id: sign
    name: "gcr.io/projectsigstore/cosign"
    entrypoint: sh
    env:
      - "TUF_ROOT=/tmp" # cosign tries to create $HOME/.sigstore
      - "COSIGN_EXPERIMENTAL=1"
      - "GOOGLE_SERVICE_ACCOUNT_NAME=cosign-signer@com-seankhliao.iam.gserviceaccount.com"
    args:
      - "-c"
      - "cosign sign gcr.io/project/image@sha256:..."
```

The cosign container runs as non root,
so it doesn't have permission to create `$HOME/.sigstore` and it dies.
Setting `TUF_ROOT` changes where it tries to do that.

#### _digests_

Container registries are a big pile of global shared state,
and if you push a tag such as `:latest` and later refer to them,
it might not be the same thing (if someone else pushed something called `:latest` in between).
Thankfully, registries are also content addressable using digests,
looking something like `sha256:....`.
How do you get one?

##### _docker_

`docker` is not very helpful,
`docker build --iidfile` outputs a file with `sha256:....`
but that's for the image's "local configuration".
Apparently the only reliable way is to push the image to a v2 registry,
and then a manifest will be generated, and you can get a digest for that.

##### _kaniko_

[kaniko](https://github.com/GoogleContainerTools/kaniko) is much better,
providing flags such as:
`--digest-file`, `--image-name-with-digest-file`, `--image-name-tag-with-digest-file`
outputting files onto the local system
which contain digests (optionally with image names), one per line.

So with cosign, the invocation becomes (assuming `--image-name-with-digest-file=.image.txt`):

```yaml
args:
  - "-c"
  - "cosign sign $(head -n 1 .image.txt)"
```
