# kyverno verifyimages bug

## all software is buggy

### _kyverno_ verifyimages

$work has a mandate:
all container images running in [Kubernetes] cluster 'prod-f' must be verified.

This was implemented as:

- container images are scanned
- passing container images are signed using [cosign] with an [AWS KMS] key
- resulting images/signatures are pushed to various accounts
- on update of a service, a [Kyverno] policy checks that the image has been signed

It sounded solid.
It was rolled out,
and it broke, but only sometimes.

#### _catching_ a bug

##### _symptoms_

Let's start with symptoms:
Kyverno would block updates to Deployments with an error like:

> error when patching "deployment-updated.k8s.yaml": admission webhook "validate.kyverno.svc-fail" denied the request:
>
> resource Deployment/default/double was blocked due to the following policies
>
> verify-image-signature:
> autogen-verify-image: unverified image ghcr.io/seankhliao/podinfo:6.3.3

Occasionally, the error would be something like

> Deployment default/xxx-agent: [autogen-verify-image] fail (blocked); kyverno.io/verify-images annotation cannot be changed

##### _more_ background info

Our 'prod-f' cluster was a _snowflake_:
One of _3_ clusters with [Istio] running,
one of _2_ clusters with an image rewriting rule active,
the _only_ cluster with image verification set to `Enforce`.
Imagine my my supreme annoyance on learning we did not have a proper testing environment,
and the way to reproduce the issue was to just try it one some of the things running in cluster until it failed.
Thankfully, we at least didn't have any customers there yet.

##### _investigation_

[Kyverno] is a bit of a black box:
you can register multiple policies with it,
but to [Kubernetes], it only registers a single pair of `MutatingWebhookConfiguration` and `ValidatingWebhookConfiguration`.
The first thing I wanted to do was look into what it was doing,
and I had not yet had enough coffee to trawl through logs.

###### _tracing_

I spun up a simple in-memory [jaeger] instance,
and pointed [kyverno's tracing] configuration at it.
Thankfully, both supported a common protocol, [OpenTelemetry OTLP], without sampling.
After some experimentation with search queries,
I finally found a few traces where it seemed to fail.
I could see that the order our various policies we applied in was valid.
Also, kyverno wasn't actually making external calls to verify the image most of the time.

###### _docs_

Time to go understand how Kyverno actually worked then.
Or at least the image verification part.
[Verify Image Rules] is the page that describes sthe process:

> When required is set to true (default) each image in the resource is checked to ensure that an immutable annotation that marks the image as verified is present.

This sounded interesting.
Annotations are mutable by default,
how was this "immutable"?
We were seeing some errors that it wasn't able to change it...
(turns out, it was via a kyverno check as part of the validating phase).

> The imageVerify rule can be combined with auto-gen so that policy rule checks are applied to Pod controllers.

So [Auto gen rules] is automatically turned on for policies affecting pods.

###### _theory_ 1

Kyverno records the result of an image verification as an "immutable" annotation,
and in the future just checks that the annotation is present with `true`.
On the update of an Deployment,
the result set needs to change,
but kyverno blocks itself from updating the result.

My recommendation was to disable auto-gen rules with.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  annotations:
    pod-policies.kyverno.io/autogen-controllers: none
```

That appeared to make the issue go away.

##### _reproduce_

Now, time to attempt to reproduce the issue locally so I can report it upstream.
But installing [Kyverno] locally in a [KinD] cluster,
I couldn't get it to break.
My updates to my Deployment went through just fine,
and Kyverno updated its (not so) immutable annotation.

Maybe, it was the image rewrite rule we also had.
I applied it into my cluster, but no dice.
Maybe it was [ArgoCD] which we used to deploy manifests using a different way of applying,
I installed that, fiddled with making changes,
but still nothing.
Maybe it was [Istio] with its sidecar injection webhook.
It was lunchtime and I didn't bother trying.

After lunch,
I had a different idea:
let's reproduce the failing Deployment more closely.
It had a main container and sidecars.
I spun up a deployment with multiple containers,
lo and behold, kyverno blocked my update.

So here's my [bug report].
Still, not very satisfied with why we sometimes saw annotation change blocked issues though.

[argocd]: https://argo-cd.readthedocs.io/en/stable/
[auto gen rules]: https://kyverno.io/docs/writing-policies/autogen/
[aws kms]: https://aws.amazon.com/kms/
[bug report]: https://github.com/kyverno/kyverno/issues/7651
[cosign]: https://github.com/sigstore/cosign
[istio]: https://istio.io/
[jaeger]: https://www.jaegertracing.io/
[kind]: https://github.com/kubernetes-sigs/kind
[kubernetes]: https://kubernetes.io/
[kyverno]: https://kyverno.io/
[kyverno's tracing]: https://kyverno.io/docs/tracing/
[opentelemetry otlp]: https://opentelemetry.io/docs/specs/otlp/
[verify image rules]: https://kyverno.io/docs/writing-policies/verify-images/
