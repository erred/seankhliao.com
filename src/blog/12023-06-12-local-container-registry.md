# local container registry

## blob stored

### _local_ container registry

Sometimes, you just need some temporary storage when working with container images.
Eg, when using crane or sigstore where every operation is a push to a remote registry.

#### _crane_ registry

[crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane)
has an in-memory implementation of docker and oci compatible
registry in [crane registry](https://github.com/google/go-containerregistry/blob/main/cmd/crane/doc/crane.md).
No auth, no permanent storage,
just a plain local cache to work with

```sh
$ go install github.com/google/go-containerregistry/cmd/crane@latest
$ PORT=8080 crane registry serve
```

#### _zot_

[zot](https://github.com/project-zot/zot)
is an oci-only registry backed by the filesystem or s3.
It does auth with mTLS, basic, LDAP, oauth2/bearer, anonymous.
Plus it has config for
[repository level auth policies](https://zotregistry.io/articles/authn-authz/#access-control-policies).
[zot config](https://zotregistry.io/v1.4.3/admin-guide/admin-configuration/).

```sh
$ zot serve /path/to/config.yaml
```

#### _distribution/distribution_

Also known as _docker.io/registry:2_.

A quite featureful registry implementation
with filesystem, memory, and cloud blob backed storage.
Auth through mTLS, basic, oauth2/bearer, anonymous.
But no policies for per-repo config.
[distribution config](https://docs.docker.com/registry/configuration/#list-of-configuration-options)

```sh
$ docker run -d -p 5000:5000 registry:2
```
