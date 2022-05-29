# what's in a container image

## the new age of fat binaries...

### _container_ image

These days there are 2 main types of container images floating around,
[docker images](https://github.com/moby/moby/blob/master/image/spec/v1.2.md)
and [oci images](https://github.com/opencontainers/image-spec/blob/main/spec.md).
Most tools understand both and they're pretty similar.

#### _crane_

[crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
is an amazing tool for manipulating container images,
allowing you to inspect / manipulate / move images with minimal overhead.

##### _ls_ and cp

These 2 are the my most used commands:

- `crane ls your.registry/your/image`: lists all the images/tags
- `crane cp source.registry/image:tag dest.registry/image:tag`: copies an image efficiently

##### _pull_

`crane pull your.registry/image:tag output.tar` pulls an image.
Expanding the archive you'll find something along the lines of:

- `manifest.json`: contains information like tags, name of config file (`sha256:<sha256>`), and the layer filenames (`<sha256>.targ.gz`)
- `sha256:<sha256>`: contains metadata like env, entrypoint, workdir, user, and also the build history/commands
- `<sha256>.tar.gz`: the individual layers, expanding these you get the contents of the (overlay) filesystems

##### _export_

`crane export your.registry/image:tag output.tar` creates a tar of the final image filesystem.
No metadata in here.

##### _append_ and mutate

- `crane append -b your.registry/base:tag -t your.registry/new:tag -f image.tar`: adds the contents of a tarball as a layer
- `crane mutate --entrypoint /app -t your.registry/new:tag your.registry/base:tag`: mutates entrypoint and/or labels of an image

This presents us with the interesting possibility of building a minimal image with just `crane`:

```sh
$ CGO_ENABLED=0 go build -o app
$ tar cf app.tar app
$ crane append -b gcr.io/distroless/static -f app.tar -t index.docker.io/seankhliao/gcrane-test:tmp
$ crane mutate index.docker.io/seankhliao/gcrane-test:tmp --entrypoint /app -t index.docker.io/seankhliao/gcrane-test:out
```

This does have some unfortunate inefficiencies:
`crane` primarily operates on images from remote registries,
so the base and intermediate images both need to come from / write to a registry.

#### _dive_

[dive](https://github.com/wagoodman/dive)
is the go to tool for exploring what's in the image at the different layers
in a terminal ui.
Use it.
