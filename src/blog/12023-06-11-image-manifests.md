# container image types

## json blobs with media types to rule the world

### _image_ manifest types

One of the great innovations of container images was their standard packaging and distribution.
Except there's more than one standard.
There's the [Docker specific variant][docker],
and there's the [OCI standard][oci].

#### _core_ concepts

##### _layers_

Building an image up from basics,
there are the image layers:
filesystems archived and compressed into a single file.
These contain the bulk of content in an image.

OCI:

- `application/vnd.oci.image.layer.v1.tar`: "Layer", as a tar archive
- `application/vnd.oci.image.layer.v1.tar+gzip`: "Layer", as a tar archive compressed with gzip
- `application/vnd.oci.image.layer.v1.tar+zstd`: "Layer", as a tar archive compressed with zstd

Docker:

- `application/vnd.docker.image.rootfs.diff.tar.gzip`: “Layer”, as a gzipped tar
- `application/vnd.docker.image.rootfs.foreign.diff.tar.gzip`: “Layer”, as a gzipped tar that should never be pushed

##### _config_

Layers by themselves don't do much,
you need some extra config,
like environment variables, entrypoint, working directory,
how to arrange the layers. and maybe some history/metadata.
This comes as its own config manifets type:

OCI:

- `application/vnd.oci.image.config.v1+json`: Image config

Docker:

- `application/vnd.docker.container.image.v1+json`: Container config JSON

##### _image_

Next is the distribution manifest that binds the config and layers together.
Most tags will point to one of these

OCI:

- `application/vnd.oci.image.manifest.v1+json`: Image manifest

Dcoker:

- `application/vnd.docker.distribution.manifest.v2+json`: New image manifest format (schemaVersion = 2)

##### _multiplatform_

But an image refers to a specifc filesystem,
maybe with platform specific artifacts (eg code compiled for arm64).
This is where the optional list/index comes in,
allowing you to specify platforms and their respective image manifests.

OCI:

- `application/vnd.oci.image.manifest.v1+json`: Image manifest

Docker:

- `application/vnd.docker.distribution.manifest.list.v2+json`: Manifest list, aka “fat manifest”

#### _tools_

- `apko publish`: creates `application/vnd.oci.image.index.v1+json`
- `buildctl build`: creates `application/vnd.docker.distribution.manifest.v2+json`
- `buildctl build --opt platform=`: creates `application/vnd.docker.distribution.manifest.list.v2+json`
  only when multiple platforms set
- `docker build`: creates `application/vnd.docker.distribution.manifest.v2+json`
- `docker buildx build`: creates `application/vnd.oci.image.manifest.v1+json`
- `docker buildx build --platform`: creates `application/vnd.oci.image.index.v1+json`
- `kaniko`: creates `application/vnd.docker.distribution.manifest.v2+json`
- `ko build`: creates `application/vnd.oci.image.manifest.v1+json`
- `ko build --platform`: creates `application/vnd.oci.image.index.v1+json`
  only when multiple platforms set
