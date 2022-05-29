# json schema, openapi, kubernetes crd

## so that's what's in my 10k line json docs...


#### _JSON_ Schema

[JSON Schema](https://json-schema.org/)
describes what your json data looks like.
Current version is draft `2020-12`/


#### _Open_ API

[Open API](https://www.openapis.org/)
describes what your (rest) api looks like.
Designed as an extension to json schema,
the current version is `3.1.0`
which importantly is finally
[100% compatible](https://www.openapis.org/blog/2021/02/18/openapi-specification-3-1-released)
with json schema
(previous versions were less (80~90%) compatible, leading to implementation headaches).

_note:_ previously it was called [swagger](https://swagger.io/),
now swagger just refers to a set of surrounding tooling

#### _kubernetes_ crds

Kubernetes
[custom resources](https://kubernetes.io/docs/concepts/extend-kubernetes/api-extension/custom-resources/)
are declared to the API server with
[`apiextentions.k8s.io/v1` `CustomResourceDefinition`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#customresourcedefinition-v1-apiextensions-k8s-io)
which describes how the API server should treat such resources
and also a validation strategy within the `openAPIV3Schema` field.
Confusingly, the description for the field says "OpenAPI v3 schema to use..."
while the field contents say "JSON-Schema following Specification Draft 4".

Since CRDs don't really describe apis other than the definition of the object
within the openAPIV3Schema field,
it's probably best to think of it as open api 3.0.0 flavored json schema.

Most controllers that make use of CRDs appear to be using
[controller-gen](https://book.kubebuilder.io/reference/controller-gen.html),
part of [kubebuilder](https://github.com/kubernetes-sigs/kubebuilder).
This means the canonical format is Go structs,
which is turned into a CRD definition directly and controlled via comments.
Which is a bit unfortunate as the openapi/json schema is never generated,
meaning tools such as
[yaml-language-server](https://github.com/redhat-developer/yaml-language-server)
need some other source than upstream.

So i think you could just extract the contents of crds `openAPIV3Schema`
from the customary yaml into json and call it a day.
The API server also serves everything it know about, via `/openapi/v2`,
and can be called with `kubectl get --raw /openapi/v2`.
I also learned there is [openapi2jsonschema](https://github.com/yannh/openapi2jsonschema)...
