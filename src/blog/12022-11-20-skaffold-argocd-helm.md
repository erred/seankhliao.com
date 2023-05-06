# skaffold argocd helm

## making different deployment tools coexist

### _ArgoCD_ + Helm environment

Say you're doing CI/CD like the cool kids:
push to git, some CI pipeline runs and builds your image,
some automated push to git happens updating a reference to your deployment,
and [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)
goes and syncs your application to the new state.

That all sounds fine, and pretty scalable for many deployment environments.
But the reality is it's quite a slow development loop when you're working with a single environment.
So what can you do?

Oh and your kubernetes manifests are rendered (but no deployed) with
[Helm](https://helm.sh/),
and it's in a top level subdirectory in your repo (`repo-root/helm/Chart.yaml`).

#### _skaffold_ options

There are a multitude of options for tools orchestrating the local-to-k8s development flow,
but here we're going to focus on [skaffold](https://skaffold.dev/)
because I like it.
(Other options include
[tilt](https://tilt.dev/),
[telepresence](https://www.telepresence.io/),
[devspace](https://www.devspace.sh/).)

skaffold v2 (which uses a config version of `skaffold/v3`...)
comes with separate [render](https://skaffold.dev/docs/pipeline-stages/renderers/)
and [deploy](https://skaffold.dev/docs/pipeline-stages/deployers/)
phases.

Because we're targeting an environment normally deployed with ArgoCD,
our only option for the deploy phase is `kubectl`.
We don't want to leave around helm deployment records that will interfere with ArgoCD operations.

As for the render phase, it's not as easy as just choose `helm`...
ArgoCD adds an extra label to deployed manifests
to allow it to track which resources are associated with which ArgoCD Application.
We need to keep those so ArgoCD will still be able to cleanup/sync after we're done with local dev.
The obvious solution for this is to use [kustomize](https://kustomize.io/)
with its built in [labels](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/labels/)
transform.

##### _helm_ + kustomize postrenderer

Helm has the option for hooking in to a [post render](https://helm.sh/docs/topics/advanced/#post-rendering) tool.
What this looks like is a shell script to write the contents of stdin to a file,
and calling `kustomize` with the configured label transform.

```yaml
# skaffold.yaml
apiVersion: skaffold/v3
kind: Config
manifests:
  helm:
    flags:
      global:
        - --post-renderer=./render/render.sh
    releases:
      - name: my-app
        chartPath: ./helm
        valuesFiles:
          - helm/values.yaml
          - helm/values/my-env.yaml
```

```sh
#!/bin/sh
# render/render.sh

cp /dev/stdin out.yaml

kustomize build .

rm out.yaml
```

```yaml
# render/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - all.yaml
labels:
  - pairs:
      my-argocd-tracking: label
    includeSelectors: false
    includeTemplates: false
```

##### _kustomize_ + helm template pre-hook

Another option using the same tools inverts the control and gets rid of the shell script,
instead using skaffold hooks to run `helm template`.

While kustomize has a [helmCharts](https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/helmcharts/)
builtin for rendering helm Charts, it's not quite flexible enough,
requiring a parent directoy holding charts, and only allowing a single values file.

```yaml
# skaffold.yaml
apiVersion: skaffold/v3
kind: Config
manifests:
  kustomize:
    paths:
      - render
  hooks:
    before:
      - host:
          command:
            - sh
            - -c
            - |
              helm template my-app ./helm -f helm/values.yaml -f helm/values/my-env.yaml > render/all.yaml
```

```yaml
# render/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - all.yaml
labels:
  - pairs:
      my-argocd-tracking: label
    includeSelectors: false
    includeTemplates: false
```
