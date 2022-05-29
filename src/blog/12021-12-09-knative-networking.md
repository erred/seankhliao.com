# knative networking

## setting up ingress for knative


### _knative_

Want GCP [Cloud Run](https://cloud.google.com/run) like functionality
but on your own hardware?
Run [Knative](https://knative.dev/).
HTTP/gRPC request based scaling,
scale to zero,
and simplified deployment manifests, what's not to like?

#### _single_ ip

Anyway, one the only choices you have to make when setting up
[Knative Serving](https://knative.dev/docs/serving/)
is which networking layer to use.

If you're like me,
you're running this on a machine with a single public IP address,
and you also need it for non-knative workloads.
Oh and TLS, I want that too.
So I need a single ingress controller that will get the `443` host port,
and can route requests to both types of workload.

I could run [Istio](https://istio.io/), but it's still a minor PITA to manage.

The second option is [kourier](https://github.com/knative-sandbox/net-kourier),
a simple [envoy](https://www.envoyproxy.io/) based ingress,
but it can't handle non knative ingresses.

Kubernetes is experimenting with a new [Gateway API](https://gateway-api.sigs.k8s.io/)
and knative has an experimental
[net-gateway-api](https://github.com/knative-sandbox/net-gateway-api) translation layer.
Unfortunately, that sort of assumes a working gateway api implementation (rare,
[traefik](https://traefik.io/) support is missing many things),
and some istio-specific things (like the internal gateway being on port 8081).

So I ended up with the [net-contour](https://github.com/knative-sandbox/net-contour)
translation layer.
This means deploying [contour](https://projectcontour.io/) twice,
once for external requests, once for an internal load balancer,
plus an extra controller to create the HTTPProxy resouces, but it works!

One thing I am questioning though
is how the internal load balancer is supposed to work without a service mesh?
You'd need to override the `service.namespace.svc.cluster.local` DNS lookups
to point to the load balancer `Service` instead of going directly to the service.
Maybe you really do need to use a custom domain for this too.
