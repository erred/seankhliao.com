# kubernetes lifecycle probes

## how are all the probes timed?

### _k8s_ probes

The [containers](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.22/#container-v1-core)
you run in kubenernetes have an array of lifecycle hooks you can configure.
like `lifecycle.postStart`, `lifecycle.preStop`, `startupProbe`, `livenessProbe`, `readinessProbe`.

#### _lifecycle_ hooks

##### _postStart_

This is called immediately after the container starts.
If you try to call the app you're starting but it's not listening yet
it will kill the pod.

##### _preStop_

This is easier to handle,
but if you have this set, then you probably also want to set `terminationGracePeriodSeconds`

#### _Probes_

These all work pretty similarly.
`initialDelaySeconds` is counted from container start,
if your startup probe eclipses the initial delay for your live/readiness probes then they have no effect.

What I think are valid combinations:

- no probes: app is ready as soon as it starts, crash on exit
- readiness: wait until the probe passes to serve traffic, crash on exit
- readiness + liveness: wait until the probe passes to serve traffic, may decide to shut itself down
- readiness + liveness + startup: same as above, but has a long startup time.

##### _startupProbe_

You probably want a short period and a high failure threshold for this one
to poll until your pods are live.
only set `initialDelaySeconds` if you know for sure your app won't be ready for the first X seconds.

Once this one passes, it is never called again and the liveness/readiness probes are called.

##### _livenessProbe_

This determines if your app is "alive",
as in kill the pod if this one fails.

##### _readinessProbe_

This determines if the pod is in the "Ready" state,
and by extension, if traffic should be routed to it.

#### _readiness_ gates

On the pod level, there are readiness gates.
These check the `pod.conditions.status` for specific conditions to be `True`.
This also means it's only really useful for k8s-aware workloads which can patch their own pods
(not available to kubectl)

#### _minReadySeconds_

Deployments and Daemonsets also have a `minReadySeconds` field that gate if the app should serve traffic.
