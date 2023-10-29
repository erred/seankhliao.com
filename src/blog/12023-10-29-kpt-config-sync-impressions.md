# kpt config-sync impressions

## Google's GitOps thing

### _config-sync_ impressions

GitOps, I want that.
Or really what I want is automatic deploys, and gitops is one way to do it.
At work that means using [ArgoCD](https://argo-cd.readthedocs.io/en/stable/)
but I don't want to deal with that for my personal cluster.
There's also [Flux](https://fluxcd.io/),
but meh.

So [Config Sync](https://cloud.google.com/anthos-config-management/docs/config-sync-overview) it is then.
Part of GCP Anthos Config Management,
but there's an open source variant at
[kpt-config-sync](https://github.com/GoogleContainerTools/kpt-config-sync)
and [kpt-resource-group](https://github.com/GoogleContainerTools/kpt-resource-group).

First thing I tried to do was deploy it,
but.... no arm64 builds.
Some fiddling with the build scripts in the two repos later,
I had a running deployment.

Next: deploy a test repo.
It worked, until I tried to remove it.
The nice thing is it has an admission webhook to enforce changes only through gitops.
Less nice is deletion is slightly more involved:
sync to an empty repo, then delete the rootsync
or mark the resources as unmanaged with the annotation `configmanagement.gke.io/managed: disabled`.

Finally, I have all the things I could ever wish to deploy in a repo.
`kubectl diff -R -f .` reports nothing,
I feel safe to apply it to the cluster.
I create a RootSync and apply.
Errors I ran into:

> Configs with "status" specified are not allowed. To fix, either remove the config or remove the "status" field in the config:"

Ok so envoy gateway managed to create some CRDs with `status` fields set,
easy enough to clean up.

> [1] KNV1011: Configs MUST NOT declare labels starting with "configmanagement.gke.io/". The config has disallowed labels: "configmanagement.gke.io/arch", "configmanagement.gke.io/system" metadata.name: admission-webhook.configsync.gke.io group: admissionregistration.k8s.io version: v1 kind: ValidatingWebhookConfiguration For more information, see https://g.co/cloud/acm-errors#knv1011
>
> [25] KNV1011: Configs MUST NOT declare labels starting with "configmanagement.gke.io/". The config has disallowed labels: "configmanagement.gke.io/system" metadata.name: namespaceselectors.configmanagement.gke.io group: apiextensions.k8s.io version: v1 kind: CustomResourceDefinition For more information, see https://g.co/cloud/acm-errors#knv1011
>
> [26] KNV1034: The "config-management-system" Namespace must not be declared metadata.name: config-management-system group: version: v1 kind: Namespace For more information, see https://g.co/cloud/acm-errors#knv1034
>
> [27] KNV1043: Anthos Configuration Management does not allow configuring CRDs in the `configmanagement.gke.io` APIGroup. To fix, please use a different APIGroup. metadata.name: clusterselectors.configmanagement.gke.io group: apiextensions.k8s.io version: v1 kind: CustomResourceDefinition For more information, see https://g.co/cloud/acm-errors#knv1043 > [31] KNV1069: RootSync config-management-system/config-sync-root must not manage itself in its repo namespace: config-management-system metadata.name: config-sync-root group: configsync.gke.io version: v1beta1 kind: RootSync For more information, see https://g.co/cloud/acm-errors#knv1069

So a lot of errors about how Config Sync really shouldn't manage itself.
Oh well, it's just a few bootstrap configs to apply by hand then...

But then it works, and it's pretty fast.
