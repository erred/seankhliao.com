# kubernetes secret stringdata

## bugs in removing stringdata fields


### _Secret_

Kubernetes Secrets are... key-value pairs of secrets.
You can create one by passing in either a raw string
or a base64 encoded string.

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: a-secret
stringData:
  foo: aaa
  bar: bbb
data:
  hello: Y2Nj
  world: ZGRk
```

While the `stringData` field is certainly convenient for both writing and reviewing,
it unfortunately has problems when you try to remove a field.
Apply the following updated version:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: a-secret
stringData:
  foo: aaa
data:
  hello: Y2Nj
```

And you get this.
Note `bar` is set to an empty string while `world` is correctly removed.

```yaml
apiVersion: v1
data:
  bar: ""
  foo: YWFh
  hello: Y2Nj
kind: Secret
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"v1","data":{"hello":"Y2Nj"},"kind":"Secret","metadata":{"annotations":{},"name":"a-secret","namespace":"default"},"stringData":{"foo":"aaa"}}
  creationTimestamp: "2021-07-31T08:09:07Z"
  name: a-secret
  namespace: default
  resourceVersion: "1346808"
  uid: 1ea0a085-fe05-4244-bdd2-79a9f6e9c51d
type: Opaque
```

What can you do about this?
You could just never use `stringData`
or use `kustomize` or the like to create a new secret every time.
