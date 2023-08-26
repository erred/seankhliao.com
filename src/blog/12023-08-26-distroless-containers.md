# distroless

## no distro, but still different

### _distroless_

The idea that you can build a minimal container with just your application and some critical dependencies,
nothing else.

It all started with [GoogleContainerTools/distroless](GoogleContainerTools/distroless)
publishing `gcr.io/distroless/static` images.
Then, at some point the [chainguard](https://chainguard.dev/)
started doing what they called v2 of distroless,
published at `cgr.dev/chainguard/static`.

Since they share(d?) some maintainers, there's some common stuff between the 2 images:

- ssl certs at `/etc/ssl/certs/ca-certificates.crt`
- timezone info at /usr/share/zoneinfo
- nonroot user 65532
- a lot of empty directories

The `gcr.io/distroless/static` images are based on Debian,
but mostly stripped clean,
with some metadata and protocol files still around.
It's 8 layers with a 2.4 MB size.

The `cgr.dev/chainguard/static` images are based on alpine,
and seem to contain even more metadata files,
plus a bunch of alpine apk keys for some reason.
It's 1 layer with a 2.0 MB size.

Though for Go binaries,
now you can `import _ "time/tzdata"` and `import _ "golang.org/x/crypto/x509roots/fallback"`
to bundle both timezone info and ca ca certificates in the binary.
This leaves a default non-root user as the main feature,
along with some directories and metadata (`/etc/protocols` anyone?)
as the differences,
which doesn't seem like a great loss,
considering the container executor can just override the user id,
and mount temp dirs when necessary (readonly root?).
