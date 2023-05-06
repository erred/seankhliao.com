# kustomize targeting array items

## how do you change the value of an array item with kustomize?

### _kustomize_ array items

Kubernetes resources use quite a few lists/arrays in defining things.
This leads to the question of how do you update the value of array items,
especially if the order of items isn't stable?

Say we have the following manifest, and we want to change `FIZZ=buzz` to `FIZZ=FUZZ`
in both deployments:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deploy
spec:
  selectors:
    matchLabels:
      foo: bar
  template:
    metdata:
      labels:
        foo: bar
    spec:
      containers:
        - name: example-container
          env:
            - name: FIZZ
              value: buzz
            - name: HELLO
              value: world
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: example-deploy-2
spec:
  selectors:
    matchLabels:
      foo: bar
  template:
    metdata:
      labels:
        foo: bar
    spec:
      containers:
        - name: with-sidecar
        - name: example-container
          env:
            - name: HELLO
              value: world
            - name: FIZZ
              value: buzz
```

#### _strategic_ merge patch

One option is to use a
[strategic merge patch](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patchesstrategicmerge/).
This uses extra data from the openapi definitions of resources
to know that certain elements should be matched using certain keys.
In this case, both the `containers` list and `env` list match using `name`.

Usually, a strategic merge patch is only applied on resources matching `metadata.name`,
but kustomize has extended that to allow targeting on
`group`, `version`, `kind`, `name`, `namespace`, `labelSelector` and `annotationSelector`
with regexes.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - original.yaml
patches:
  - patch: |
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: placeholder
      spec:
        template:
          spec:
            containers:
              - name: example-container
                env:
                  - name: FIZZ
                    value: FUZZ
    target:
      kind: Deployment
```

#### _replacements_

The other option makes use of
[replacements](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/replacements/).
This gives you more explicit control over how array items are targeted,
but I havent thought of a good way to feed structured data in to it.

This example creates a temporary config map to hold that data that we later reference.
The `config.kubernetes.io/local-config: "true"` annotation
tells `kustomize` not to include it in the final output.
Then we define a replacement, sourcing data from the configmap we just created,
and targeting resources with the `[key=value]` item key selector.

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - original.yaml
configMapGenerator:
  - name: data-source
    options:
      disableNameSuffixHash: true
      annotations:
        config.kubernetes.io/local-config: "true"
    literals:
      - new-value=FUZZ
replacements:
  - source:
      name: data-source
      fieldPath: data.new-value
    targets:
      - select:
          kind: Deployment
        fieldPaths:
          - spec.template.spec.containers.[name=example-container].env.[name=FIZZ].value
```
