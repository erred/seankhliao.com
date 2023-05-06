# melange and apko

## building containers halfway declaratively

### _apko_ and melange

[apko](https://apko.dev/)
and [melange](https://github.com/chainguard-dev/melange)
are 2 interesting tools
[coming from](https://blog.chainguard.dev/introducing-apko-bringing-distroless-nirvana-to-alpine-linux/)
[chainguard.dev](https://chainguard.dev/)
aiming for declarative builds of alpine packages and containers based on the apk ecosystem.

#### _melange_

`melange` is for building apk packages, generating, and signing repository indexes.
It consists of: package metadata,
packages to be installed in the build environment,
and a linear pipeline of steps,
using either reusable stages declared in yaml on disk,
or inline scripts.
A config for building a Go application might look like:

```yaml
# package metadata
package:
  name: my-package
  description: some description
  version: 0.0.1
  epoch: 0
  target-architecture:
    - all
  copyright:
    - paths:
        - "*"
      license: MIT
      # attestation
  # dependencies:
  #   runtime:
  #   provides:
  # scriptlets:
  #   pre-install:
  #   post-install:
  #   ...

# build environment
environment:
  contents:
    repositories:
      - https://dl-cdn.alpinelinux.org/alpine/edge/main
      - https://dl-cdn.alpinelinux.org/alpine/edge/community
    packages:
      # always necessary
      - alpine-baselayout-data
      # i think things break without this
      - busybox
      # connect to the outside world, eg GOPROXY
      - ca-certificates-bundle
      # buildvcs stamping
      - git
      # build tool
      - go

pipeline:
  # melange comes with some basic declarative pipelines
  # (someone else wrote the script in yaml for you)
  # but you can always just include a shell script
  - runs: |
      mkdir -p "${{targets.destdir}}"
      go build -trimpath -ldflags='-s -w' -o "${{targets.destdir}}/usr/bin/" .
```

`melange` relies on some alpine tools,
on other systems docker can be used to run it with something like:

```sh
$ docker run --privileged -v $(PWD):/work distroless.dev/melange:latest \
  build \
  --arch x86_64 \
  --signing-key build/melange.rsa \
  --out-dir /work/build/packages \
  melange.yaml
```

- `/work` is the preferred workspace, used with defaults
- by default it uses builds for all architectures, might be slow as you repeat builds
- `--privileged` is necessary for `bubblewrap` to do some sort of containing
- `--sigining-key` should be used to sign the index if used with `apko` (only accepts signed repos)

#### _apko_

`apko` composes packages into container images.
It appears that any complex config will need to be done by building a package
and including that.

```yaml
contents:
  # repositories to pull packages from
  # NOTE: these need to be signed
  repositories:
    - https://dl-cdn.alpinelinux.org/alpine/edge/main
    - https://dl-cdn.alpinelinux.org/alpine/edge/community
    # syntax for local repo
    - "@local /work/build/packages"
  packages:
    - alpine-baselayout
    - weechat
    # pull from local repo
    - example-package@local

# dockerfile ENTRYPOINT
entrypoint:
  command: "fly-weechat"

# run as non root
accounts:
  run-as: 10000
  users:
    - username: user
      uid: 10000
  groups:
    - groupname: user
      gid: 10000

# setup a home for our user
environment:
  HOME: /home/user

paths:
  - path: /home/user
    type: directory
    uid: 10000
    gid: 10000
    permissions: 0o755
```

This also has a dependency on alpine tools,
so here comes docker again.
Alternatively, use `publish` to push directly to a repository.

```sh
$ docker run -v $(PWD):/work distroless.dev/apko:latest \
  build \
  --keyring-append build/melange.rsa.pub \
  apko.yaml \
  ${IMAGE_NAME}:${IMAGE_REF} \
  build/image.tar
```

- `apko` only accepts signed repositories, otherwise the error is not very helpful

#### _makefile_

While they are declarative,
unlike [ko](https://ko.build/) which inspired it,
it's not quite there in terms of no runtime config (flags) needed.
So we're back to writing a `Makefile` to remember all the commands.

```Makefile
IMAGE_NAME := "my.registry.example/img"
IMAGE_REF := "latest"
IMAGE_OUT := "image.tar"

SRC := $(shell find . -name '*.go')

$(SRC) go.mod go.sum melange.yaml apko.yaml:

gen-keys: build/melange.rsa
build/melange.rsa:
	mkdir -p build/
	docker run --privileged -v $(PWD):/work distroless.dev/melange:latest \
		keygen build/melange.rsa

build-apk: build/packages/x86_64/APKINDEX.tar.gz
build/packages/x86_64/APKINDEX.tar.gz: gen-keys $(SRC) go.mod go.sum melange.yaml
	docker run --privileged -v $(PWD):/work distroless.dev/melange:latest \
		build \
		--arch x86_64 \
		--signing-key build/melange.rsa \
		--out-dir /work/build/packages \
		melange.yaml

build-img: build/image.tar
build/image.tar: build-apk apko.yaml
	docker run -v $(PWD):/work distroless.dev/apko:latest \
		build \
		--keyring-append build/melange.rsa.pub \
		apko.yaml \
		${IMAGE_NAME}:${IMAGE_REF} \
		build/image.tar

load-img: build-img
	docker load -i build/image.tar

.PHONY: run-img
run-img: load-img
	docker run --rm -it ${IMAGE_NAME}:${IMAGE_REF}
```
